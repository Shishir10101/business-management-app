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
/// Purchases: stock increases, the credit portion lands on the supplier's
/// khata as a payable, bill numbers are sequential, and delete reverses both.
/// </summary>
[Collection(ApiTestCollection.Name)]
public class PurchaseEndpointsTests
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web)
    {
        Converters = { new JsonStringEnumConverter() },
    };

    private readonly KhataApiFactory _factory;

    public PurchaseEndpointsTests(KhataApiFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task CreatePurchase_Credit_IncreasesStock_AndRecordsSupplierPayable()
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, $"Flour {Guid.NewGuid():n}", costPrice: 6000);
        var supplier = await CreateSupplierAsync(client, $"Mill {Guid.NewGuid():n}");

        var purchase = await CreatePurchaseAsync(client, new
        {
            supplierId = supplier.Id,
            purchaseType = "Credit",
            items = new[] { new { productId = product.Id, quantity = 20, unitPrice = 6000L } },
            paidAmount = 0L,
        });

        Assert.Equal(120000, purchase.TotalAmount);
        Assert.Equal(120000, purchase.DueAmount);
        Assert.Equal(PaymentStatus.Unpaid, purchase.PaymentStatus);
        Assert.Equal("BILL-00001", purchase.BillNumber);

        // Stock went up by 20.
        Assert.Equal(20m, await GetStockAsync(client, product.Id));

        // Supplier khata: we owe more → one Credit.
        var ledger = await GetSupplierLedgerAsync(client, supplier.Id);
        var txn = Assert.Single(ledger.Data);
        Assert.Equal(LedgerEntryType.Credit, txn.TransactionType);
        Assert.Equal(120000, txn.Amount);
        Assert.Equal("purchase", txn.ReferenceType);
        Assert.Equal(120000, ledger.Summary.ClosingBalance);
    }

    [Fact]
    public async Task CreatePurchase_Cash_DoesNotTouchKhata()
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, $"Cash {Guid.NewGuid():n}", costPrice: 5000);
        var supplier = await CreateSupplierAsync(client, $"Cash Sup {Guid.NewGuid():n}");

        var purchase = await CreatePurchaseAsync(client, new
        {
            supplierId = supplier.Id,
            purchaseType = "Cash",
            items = new[] { new { productId = product.Id, quantity = 4, unitPrice = 5000L } },
            paidAmount = 20000L,
        });

        Assert.Equal(20000, purchase.PaidAmount);
        Assert.Equal(0, purchase.DueAmount);
        Assert.Empty((await GetSupplierLedgerAsync(client, supplier.Id)).Data);
    }

    [Fact]
    public async Task CreatePurchase_AllocatesSequentialBillNumbers()
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, $"Seq {Guid.NewGuid():n}", costPrice: 1000);

        var first = await CreatePurchaseAsync(client, CashPurchase(product.Id, 1, 1000));
        var second = await CreatePurchaseAsync(client, CashPurchase(product.Id, 1, 1000));

        Assert.Equal("BILL-00001", first.BillNumber);
        Assert.Equal("BILL-00002", second.BillNumber);
    }

    [Fact]
    public async Task CreatePurchase_CreditWithoutSupplier_Returns422()
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, $"NoSup {Guid.NewGuid():n}", costPrice: 1000);

        var response = await client.PostAsJsonAsync("/api/purchases", new
        {
            supplierId = (long?)null,
            purchaseType = "Credit",
            items = new[] { new { productId = product.Id, quantity = 1, unitPrice = 1000L } },
            paidAmount = 0L,
        });

        Assert.Equal(HttpStatusCode.UnprocessableEntity, response.StatusCode);
    }

    [Fact]
    public async Task DeletePurchase_RemovesStock_AndReversesPayable()
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, $"Reverse {Guid.NewGuid():n}", costPrice: 2000);
        var supplier = await CreateSupplierAsync(client, $"Reverse Sup {Guid.NewGuid():n}");

        var purchase = await CreatePurchaseAsync(client, new
        {
            supplierId = supplier.Id,
            purchaseType = "Credit",
            items = new[] { new { productId = product.Id, quantity = 10, unitPrice = 2000L } },
            paidAmount = 0L,
        });
        Assert.Equal(10m, await GetStockAsync(client, product.Id));

        var delete = await client.DeleteAsync($"/api/purchases/{purchase.Id}");
        Assert.Equal(HttpStatusCode.NoContent, delete.StatusCode);

        // Stock removed again, payable cleared.
        Assert.Equal(0m, await GetStockAsync(client, product.Id));

        var ledger = await GetSupplierLedgerAsync(client, supplier.Id);
        Assert.Equal(0, ledger.Summary.ClosingBalance);
        Assert.Equal(2, ledger.Data.Count);
        Assert.Equal("purchase_reversal", ledger.Data[0].ReferenceType);
        Assert.Equal(LedgerEntryType.Debit, ledger.Data[0].TransactionType);

        var get = await client.GetAsync($"/api/purchases/{purchase.Id}");
        Assert.Equal(HttpStatusCode.NotFound, get.StatusCode);
    }

    [Fact]
    public async Task OtherBusiness_CannotSeePurchase_Returns404()
    {
        var ownerA = await CreateOwnerClientAsync();
        var productA = await CreateProductAsync(ownerA, $"Private {Guid.NewGuid():n}", costPrice: 1000);
        var purchaseA = await CreatePurchaseAsync(ownerA, CashPurchase(productA.Id, 1, 1000));

        var ownerB = await CreateOwnerClientAsync();

        var get = await ownerB.GetAsync($"/api/purchases/{purchaseA.Id}");
        Assert.Equal(HttpStatusCode.NotFound, get.StatusCode);
    }

    // --- helpers ---

    private static object CashPurchase(long productId, decimal quantity, long unitPrice) => new
    {
        purchaseType = "Cash",
        items = new[] { new { productId, quantity, unitPrice } },
        paidAmount = (long)Math.Round(quantity * unitPrice),
    };

    private static async Task<PurchaseDto> CreatePurchaseAsync(HttpClient client, object body)
    {
        var response = await client.PostAsJsonAsync("/api/purchases", body);
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<PurchaseDto>(JsonOptions))!;
    }

    private static async Task<decimal> GetStockAsync(HttpClient client, long productId)
    {
        var product = await client.GetFromJsonAsync<ProductDto>($"/api/products/{productId}", JsonOptions);
        return product!.StockQuantity;
    }

    private static async Task<PartyLedgerDto> GetSupplierLedgerAsync(HttpClient client, long supplierId)
        => (await client.GetFromJsonAsync<PartyLedgerDto>(
            $"/api/suppliers/{supplierId}/ledger?pageSize=100", JsonOptions))!;

    private static async Task<ProductDto> CreateProductAsync(
        HttpClient client, string name, long costPrice, long sellingPrice = 0)
    {
        var response = await client.PostAsJsonAsync("/api/products", new
        {
            name,
            costPrice,
            sellingPrice,
            openingQuantity = 0,
        });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<ProductDto>(JsonOptions))!;
    }

    private static async Task<SupplierDto> CreateSupplierAsync(HttpClient client, string name)
    {
        var response = await client.PostAsJsonAsync("/api/suppliers", new { name });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<SupplierDto>(JsonOptions))!;
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
