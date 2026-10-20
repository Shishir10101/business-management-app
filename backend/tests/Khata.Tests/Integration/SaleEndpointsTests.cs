using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Domain.Enums;
using Khata.Tests.Testing;
using Xunit;

namespace Khata.Tests.Integration;

/// <summary>
/// Sales: the create workflow (stock + khata + payment + invoice number in one
/// transaction), payment-type rules, totals math, delete-as-reversal, and
/// cross-business isolation.
/// </summary>
[Collection(ApiTestCollection.Name)]
public class SaleEndpointsTests
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web)
    {
        Converters = { new JsonStringEnumConverter() },
    };

    private readonly KhataApiFactory _factory;

    public SaleEndpointsTests(KhataApiFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task CreateSale_Cash_DecrementsStock_AndLeavesKhataEmpty()
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, $"Wai Wai {Guid.NewGuid():n}",
            sellingPrice: 2000, openingQuantity: 50);
        var customer = await CreateCustomerAsync(client, $"Cash {Guid.NewGuid():n}");

        var sale = await CreateSaleAsync(client, new
        {
            customerId = customer.Id,
            saleType = "Cash",
            items = new[] { new { productId = product.Id, quantity = 5, unitPrice = 2000L } },
            paidAmount = 10000L,
        });

        Assert.Equal(10000, sale.TotalAmount);
        Assert.Equal(10000, sale.PaidAmount);
        Assert.Equal(0, sale.DueAmount);
        Assert.Equal(PaymentStatus.Paid, sale.PaymentStatus);
        Assert.Equal("INV-00001", sale.InvoiceNumber);
        Assert.Single(sale.Items);

        Assert.Equal(45m, await GetStockAsync(client, product.Id));
        Assert.Empty((await GetCustomerLedgerAsync(client, customer.Id)).Data);
    }

    [Fact]
    public async Task CreateSale_Credit_RecordsLedgerDebitForFullTotal()
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, $"Rice {Guid.NewGuid():n}",
            sellingPrice: 110000, openingQuantity: 20);
        var customer = await CreateCustomerAsync(client, $"Credit {Guid.NewGuid():n}");

        var sale = await CreateSaleAsync(client, new
        {
            customerId = customer.Id,
            saleType = "Credit",
            items = new[] { new { productId = product.Id, quantity = 2, unitPrice = 110000L } },
            paidAmount = 0L,
        });

        Assert.Equal(220000, sale.TotalAmount);
        Assert.Equal(0, sale.PaidAmount);
        Assert.Equal(220000, sale.DueAmount);
        Assert.Equal(PaymentStatus.Unpaid, sale.PaymentStatus);

        // Khata: customer owes more → one Debit of the full total.
        var ledger = await GetCustomerLedgerAsync(client, customer.Id);
        var txn = Assert.Single(ledger.Data);
        Assert.Equal(LedgerEntryType.Debit, txn.TransactionType);
        Assert.Equal(220000, txn.Amount);
        Assert.Equal(220000, txn.BalanceAfter);
        Assert.Equal("sale", txn.ReferenceType);
        Assert.Equal(sale.Id, txn.ReferenceId);
        Assert.Equal(220000, ledger.Summary.ClosingBalance);
    }

    [Fact]
    public async Task CreateSale_Partial_OnlyDuePortionHitsKhata()
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, $"Oil {Guid.NewGuid():n}",
            sellingPrice: 50000, openingQuantity: 10);
        var customer = await CreateCustomerAsync(client, $"Partial {Guid.NewGuid():n}");

        var sale = await CreateSaleAsync(client, new
        {
            customerId = customer.Id,
            saleType = "Partial",
            items = new[] { new { productId = product.Id, quantity = 2, unitPrice = 50000L } },
            paidAmount = 40000L,
        });

        Assert.Equal(100000, sale.TotalAmount);
        Assert.Equal(40000, sale.PaidAmount);
        Assert.Equal(60000, sale.DueAmount);
        Assert.Equal(PaymentStatus.Partial, sale.PaymentStatus);

        var ledger = await GetCustomerLedgerAsync(client, customer.Id);
        var txn = Assert.Single(ledger.Data);
        Assert.Equal(60000, txn.Amount);
        Assert.Equal(60000, ledger.Summary.ClosingBalance);
    }

    [Fact]
    public async Task CreateSale_ComputesTotals_WithLineAndHeaderDiscountAndTax()
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, $"Taxed {Guid.NewGuid():n}",
            sellingPrice: 10000, taxRateBps: 1300, openingQuantity: 10);

        var sale = await CreateSaleAsync(client, new
        {
            saleType = "Cash",
            discountAmount = 500L,
            items = new[]
            {
                new { productId = product.Id, quantity = 2, unitPrice = 10000L, discountAmount = 1000L },
            },
            paidAmount = 20970L,
        });

        // gross 20000 − line discount 1000 = 19000; tax 13% = 2470;
        // total = 20000 − (1000 + 500) + 2470 = 20970.
        Assert.Equal(20000, sale.Subtotal);
        Assert.Equal(1500, sale.DiscountAmount);
        Assert.Equal(2470, sale.TaxAmount);
        Assert.Equal(20970, sale.TotalAmount);

        var item = Assert.Single(sale.Items);
        Assert.Equal(10000, item.UnitPrice);
        Assert.Equal(1000, item.DiscountAmount);
        Assert.Equal(2470, item.TaxAmount);
        Assert.Equal(21470, item.LineTotal);
    }

    [Fact]
    public async Task CreateSale_AllocatesSequentialInvoiceNumbers()
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, $"Seq {Guid.NewGuid():n}",
            sellingPrice: 1000, openingQuantity: 100);

        var first = await CreateSaleAsync(client, CashSale(product.Id, 1, 1000));
        var second = await CreateSaleAsync(client, CashSale(product.Id, 1, 1000));
        var third = await CreateSaleAsync(client, CashSale(product.Id, 1, 1000));

        Assert.Equal("INV-00001", first.InvoiceNumber);
        Assert.Equal("INV-00002", second.InvoiceNumber);
        Assert.Equal("INV-00003", third.InvoiceNumber);
    }

    [Fact]
    public async Task CreateSale_InsufficientStock_Returns422()
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, $"Short {Guid.NewGuid():n}",
            sellingPrice: 1000, openingQuantity: 5);

        var response = await client.PostAsJsonAsync("/api/sales", new
        {
            saleType = "Cash",
            items = new[] { new { productId = product.Id, quantity = 10, unitPrice = 1000L } },
            paidAmount = 10000L,
        });

        Assert.Equal(HttpStatusCode.UnprocessableEntity, response.StatusCode);
        // Stock untouched by the failed sale.
        Assert.Equal(5m, await GetStockAsync(client, product.Id));
    }

    [Fact]
    public async Task CreateSale_CreditWithoutCustomer_Returns422()
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, $"NoCust {Guid.NewGuid():n}",
            sellingPrice: 1000, openingQuantity: 10);

        var response = await client.PostAsJsonAsync("/api/sales", new
        {
            customerId = (long?)null,
            saleType = "Credit",
            items = new[] { new { productId = product.Id, quantity = 1, unitPrice = 1000L } },
            paidAmount = 0L,
        });

        Assert.Equal(HttpStatusCode.UnprocessableEntity, response.StatusCode);
    }

    [Theory]
    [InlineData("Cash", 500L)]      // cash must be fully paid
    [InlineData("Credit", 500L)]    // credit must have no payment
    public async Task CreateSale_PaymentTypeMismatch_Returns422(string saleType, long paid)
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, $"Mismatch {Guid.NewGuid():n}",
            sellingPrice: 1000, openingQuantity: 10);
        var customer = await CreateCustomerAsync(client, $"Mismatch {Guid.NewGuid():n}");

        var response = await client.PostAsJsonAsync("/api/sales", new
        {
            customerId = customer.Id,
            saleType,
            items = new[] { new { productId = product.Id, quantity = 1, unitPrice = 1000L } },
            paidAmount = paid,
        });

        Assert.Equal(HttpStatusCode.UnprocessableEntity, response.StatusCode);
    }

    [Fact]
    public async Task CreateSale_PaidExceedsTotal_Returns422()
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, $"Over {Guid.NewGuid():n}",
            sellingPrice: 1000, openingQuantity: 10);

        var response = await client.PostAsJsonAsync("/api/sales", new
        {
            saleType = "Cash",
            items = new[] { new { productId = product.Id, quantity = 1, unitPrice = 1000L } },
            paidAmount = 5000L,
        });

        Assert.Equal(HttpStatusCode.UnprocessableEntity, response.StatusCode);
    }

    [Fact]
    public async Task CreateSale_WithEmptyItems_Returns400()
    {
        var client = await CreateOwnerClientAsync();

        var response = await client.PostAsJsonAsync("/api/sales", new
        {
            saleType = "Cash",
            items = Array.Empty<object>(),
            paidAmount = 0L,
        });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task CreateSale_WithNonPositiveQuantity_Returns400()
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, $"ZeroQty {Guid.NewGuid():n}",
            sellingPrice: 1000, openingQuantity: 10);

        var response = await client.PostAsJsonAsync("/api/sales", new
        {
            saleType = "Cash",
            items = new[] { new { productId = product.Id, quantity = 0, unitPrice = 1000L } },
            paidAmount = 0L,
        });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task CreateSale_UnknownProduct_Returns404()
    {
        var client = await CreateOwnerClientAsync();

        var response = await client.PostAsJsonAsync("/api/sales", new
        {
            saleType = "Cash",
            items = new[] { new { productId = 999999L, quantity = 1, unitPrice = 1000L } },
            paidAmount = 1000L,
        });

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task DeleteSale_RestoresStock_AndReversesKhata()
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, $"Reversed {Guid.NewGuid():n}",
            sellingPrice: 10000, openingQuantity: 30);
        var customer = await CreateCustomerAsync(client, $"Reversed {Guid.NewGuid():n}");

        var sale = await CreateSaleAsync(client, new
        {
            customerId = customer.Id,
            saleType = "Credit",
            items = new[] { new { productId = product.Id, quantity = 5, unitPrice = 10000L } },
            paidAmount = 0L,
        });
        Assert.Equal(25m, await GetStockAsync(client, product.Id));
        Assert.Equal(50000, (await GetCustomerLedgerAsync(client, customer.Id)).Summary.ClosingBalance);

        var delete = await client.DeleteAsync($"/api/sales/{sale.Id}");
        Assert.Equal(HttpStatusCode.NoContent, delete.StatusCode);

        // Stock restored, khata credited back to zero.
        Assert.Equal(30m, await GetStockAsync(client, product.Id));

        var ledger = await GetCustomerLedgerAsync(client, customer.Id);
        Assert.Equal(0, ledger.Summary.ClosingBalance);
        Assert.Equal(2, ledger.Data.Count);
        Assert.Equal("sale_reversal", ledger.Data[0].ReferenceType);
        Assert.Equal(LedgerEntryType.Credit, ledger.Data[0].TransactionType);

        // Gone from the list and detail.
        var get = await client.GetAsync($"/api/sales/{sale.Id}");
        Assert.Equal(HttpStatusCode.NotFound, get.StatusCode);
        var list = await GetSalesAsync(client);
        Assert.DoesNotContain(list, s => s.Id == sale.Id);
    }

    [Fact]
    public async Task GetSales_FiltersByTypeStatusAndSearch()
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, $"Filter {Guid.NewGuid():n}",
            sellingPrice: 1000, openingQuantity: 100);
        var customer = await CreateCustomerAsync(client, $"Filtered {Guid.NewGuid():n}");

        var credit = await CreateSaleAsync(client, new
        {
            customerId = customer.Id,
            saleType = "Credit",
            items = new[] { new { productId = product.Id, quantity = 1, unitPrice = 1000L } },
            paidAmount = 0L,
        });
        await CreateSaleAsync(client, CashSale(product.Id, 1, 1000));

        var unpaid = await GetSalesAsync(client, "paymentStatus=Unpaid");
        Assert.Contains(unpaid, s => s.Id == credit.Id);
        Assert.All(unpaid, s => Assert.Equal(PaymentStatus.Unpaid, s.PaymentStatus));

        var byInvoice = await GetSalesAsync(client, $"search={credit.InvoiceNumber}");
        Assert.Single(byInvoice);
        Assert.Equal(credit.Id, byInvoice[0].Id);

        var byCustomer = await GetSalesAsync(client, $"search={Uri.EscapeDataString(customer.Name)}");
        Assert.Contains(byCustomer, s => s.Id == credit.Id);
    }

    [Fact]
    public async Task OtherBusiness_CannotSeeSale_Returns404()
    {
        var ownerA = await CreateOwnerClientAsync();
        var productA = await CreateProductAsync(ownerA, $"Private {Guid.NewGuid():n}",
            sellingPrice: 1000, openingQuantity: 10);
        var saleA = await CreateSaleAsync(ownerA, CashSale(productA.Id, 1, 1000));

        var ownerB = await CreateOwnerClientAsync();

        var get = await ownerB.GetAsync($"/api/sales/{saleA.Id}");
        Assert.Equal(HttpStatusCode.NotFound, get.StatusCode);

        var list = await GetSalesAsync(ownerB);
        Assert.DoesNotContain(list, s => s.Id == saleA.Id);
    }

    // --- helpers ---

    private static object CashSale(long productId, decimal quantity, long unitPrice) => new
    {
        saleType = "Cash",
        items = new[] { new { productId, quantity, unitPrice } },
        paidAmount = (long)Math.Round(quantity * unitPrice),
    };

    private static async Task<SaleDto> CreateSaleAsync(HttpClient client, object body)
    {
        var response = await client.PostAsJsonAsync("/api/sales", body);
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<SaleDto>(JsonOptions))!;
    }

    private static async Task<List<SaleDto>> GetSalesAsync(HttpClient client, string? query = null)
    {
        var url = "/api/sales?pageSize=100" + (query is null ? "" : "&" + query);
        var page = await client.GetFromJsonAsync<PagedResult<SaleDto>>(url, JsonOptions);
        return page!.Data.ToList();
    }

    private static async Task<decimal> GetStockAsync(HttpClient client, long productId)
    {
        var product = await client.GetFromJsonAsync<ProductDto>($"/api/products/{productId}", JsonOptions);
        return product!.StockQuantity;
    }

    private static async Task<PartyLedgerDto> GetCustomerLedgerAsync(HttpClient client, long customerId)
        => (await client.GetFromJsonAsync<PartyLedgerDto>(
            $"/api/customers/{customerId}/ledger?pageSize=100", JsonOptions))!;

    private static async Task<ProductDto> CreateProductAsync(
        HttpClient client, string name, long sellingPrice, int taxRateBps = 0,
        double openingQuantity = 0, long costPrice = 0)
    {
        var response = await client.PostAsJsonAsync("/api/products", new
        {
            name,
            sellingPrice,
            costPrice,
            taxRateBps,
            openingQuantity,
        });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<ProductDto>(JsonOptions))!;
    }

    private static async Task<CustomerDto> CreateCustomerAsync(
        HttpClient client, string name, long openingBalance = 0)
    {
        var response = await client.PostAsJsonAsync("/api/customers", new { name, openingBalance });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<CustomerDto>(JsonOptions))!;
    }

    /// <summary>Registers a user, creates a business, switches to it (Owner JWT).</summary>
    private async Task<HttpClient> CreateOwnerClientAsync()
    {
        var client = await AuthEndpointsTests.CreateAuthenticatedClientAsync(_factory);

        var create = await client.PostAsJsonAsync("/api/businesses", new
        {
            name = $"Shop {Guid.NewGuid():n}",
            currency = "NPR",
        });
        create.EnsureSuccessStatusCode();
        var business = await create.Content.ReadFromJsonAsync<BusinessDto>(JsonOptions);

        var switchResponse = await client.PostAsJsonAsync($"/api/businesses/{business!.Id}/switch", new { });
        switchResponse.EnsureSuccessStatusCode();
        var auth = await switchResponse.Content.ReadFromJsonAsync<AuthResponse>(JsonOptions);
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", auth!.AccessToken);

        return client;
    }
}
