using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Domain.Enums;
using Khata.Tests.Testing;
using Xunit;

namespace Khata.Tests.Integration;

/// <summary>
/// Quotations: numbering, totals, PDF rendering, and conversion into a real
/// sale (stock + khata), including the guards around re-conversion.
/// </summary>
[Collection(ApiTestCollection.Name)]
public class QuotationEndpointsTests
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web)
    {
        Converters = { new JsonStringEnumConverter() },
    };

    private readonly KhataApiFactory _factory;

    public QuotationEndpointsTests(KhataApiFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task CreateQuotation_AllocatesQuoteNumber_AndComputesTotals()
    {
        var client = await CreateOwnerClientAsync();
        var customer = await CreateCustomerAsync(client);

        var quotation = await CreateQuotationAsync(client, new
        {
            customerId = customer.Id,
            validUntil = "2026-11-30",
            items = new[]
            {
                new { description = "Custom furniture", quantity = 1, unitPrice = 2500000L, taxRateBps = 1300 },
            },
        });

        Assert.Equal("QT-00001", quotation.QuoteNumber);
        Assert.Equal(QuotationStatus.Draft, quotation.Status);
        Assert.Equal(2500000, quotation.Subtotal);
        Assert.Equal(325000, quotation.TaxAmount);
        Assert.Equal(2825000, quotation.TotalAmount);
        Assert.Null(quotation.ConvertedSaleId);
    }

    [Fact]
    public async Task CreateQuotation_AllocatesSequentialNumbers()
    {
        var client = await CreateOwnerClientAsync();

        var first = await CreateQuotationAsync(client, new
        {
            items = new[] { new { description = "A", quantity = 1, unitPrice = 100L } },
        });
        var second = await CreateQuotationAsync(client, new
        {
            items = new[] { new { description = "B", quantity = 1, unitPrice = 100L } },
        });

        Assert.Equal("QT-00001", first.QuoteNumber);
        Assert.Equal("QT-00002", second.QuoteNumber);
    }

    [Fact]
    public async Task ConvertToSale_CreatesTheSale_WithStockAndKhata_AndMarksAccepted()
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, sellingPrice: 10000, openingQuantity: 20);
        var customer = await CreateCustomerAsync(client);

        var quotation = await CreateQuotationAsync(client, new
        {
            customerId = customer.Id,
            items = new[] { new { productId = product.Id, quantity = 3, unitPrice = 10000L } },
        });
        Assert.Equal(30000, quotation.TotalAmount);

        var response = await client.PostAsJsonAsync($"/api/quotations/{quotation.Id}/convert", new
        {
            saleType = "Credit",
            paidAmount = 0L,
        });
        response.EnsureSuccessStatusCode();
        var sale = await response.Content.ReadFromJsonAsync<SaleDto>(JsonOptions);

        Assert.Equal(30000, sale!.TotalAmount);
        Assert.Equal(PaymentStatus.Unpaid, sale.PaymentStatus);
        Assert.Contains(quotation.QuoteNumber, sale.Notes);
        Assert.Single(sale.Items);
        Assert.Equal(product.Id, sale.Items[0].ProductId);

        // Stock moved and the customer khata was debited.
        var refreshedProduct = await client.GetFromJsonAsync<ProductDto>($"/api/products/{product.Id}", JsonOptions);
        Assert.Equal(17, refreshedProduct!.StockQuantity);

        var ledger = await client.GetFromJsonAsync<PartyLedgerDto>(
            $"/api/customers/{customer.Id}/ledger?pageSize=100", JsonOptions);
        Assert.Equal(30000, ledger!.Summary.ClosingBalance);

        // The quotation is marked accepted and linked to the sale.
        var refreshed = await client.GetFromJsonAsync<QuotationDto>($"/api/quotations/{quotation.Id}", JsonOptions);
        Assert.Equal(QuotationStatus.Accepted, refreshed!.Status);
        Assert.Equal(sale.Id, refreshed.ConvertedSaleId);
    }

    [Fact]
    public async Task ConvertTheSameQuotationTwice_Returns422()
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, 5000, 10);
        var customer = await CreateCustomerAsync(client);
        var quotation = await CreateQuotationAsync(client, new
        {
            customerId = customer.Id,
            items = new[] { new { productId = product.Id, quantity = 1, unitPrice = 5000L } },
        });

        var first = await client.PostAsJsonAsync($"/api/quotations/{quotation.Id}/convert",
            new { saleType = "Credit", paidAmount = 0L });
        first.EnsureSuccessStatusCode();

        var second = await client.PostAsJsonAsync($"/api/quotations/{quotation.Id}/convert",
            new { saleType = "Credit", paidAmount = 0L });
        Assert.Equal(HttpStatusCode.UnprocessableEntity, second.StatusCode);
    }

    [Fact]
    public async Task ConvertQuotationWithAFreeTextLine_Returns422()
    {
        var client = await CreateOwnerClientAsync();
        var customer = await CreateCustomerAsync(client);
        var quotation = await CreateQuotationAsync(client, new
        {
            customerId = customer.Id,
            items = new[] { new { description = "Consulting services", quantity = 1, unitPrice = 100000L } },
        });

        var response = await client.PostAsJsonAsync($"/api/quotations/{quotation.Id}/convert",
            new { saleType = "Credit", paidAmount = 0L });

        Assert.Equal(HttpStatusCode.UnprocessableEntity, response.StatusCode);
    }

    [Fact]
    public async Task ConvertQuotationWithoutACustomer_AsCredit_Returns422()
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, 5000, 10);
        var quotation = await CreateQuotationAsync(client, new
        {
            items = new[] { new { productId = product.Id, quantity = 1, unitPrice = 5000L } },
        });

        var response = await client.PostAsJsonAsync($"/api/quotations/{quotation.Id}/convert",
            new { saleType = "Credit", paidAmount = 0L });

        Assert.Equal(HttpStatusCode.UnprocessableEntity, response.StatusCode);
    }

    [Fact]
    public async Task UpdateConvertedQuotation_Returns422()
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, 5000, 10);
        var customer = await CreateCustomerAsync(client);
        var quotation = await CreateQuotationAsync(client, new
        {
            customerId = customer.Id,
            items = new[] { new { productId = product.Id, quantity = 1, unitPrice = 5000L } },
        });

        var convert = await client.PostAsJsonAsync($"/api/quotations/{quotation.Id}/convert",
            new { saleType = "Credit", paidAmount = 0L });
        convert.EnsureSuccessStatusCode();

        var response = await client.PutAsJsonAsync($"/api/quotations/{quotation.Id}", new
        {
            customerId = customer.Id,
            items = new[] { new { description = "Changed", quantity = 1, unitPrice = 100L } },
        });

        Assert.Equal(HttpStatusCode.UnprocessableEntity, response.StatusCode);
    }

    [Fact]
    public async Task QuotationPdf_RendersAWellFormedPdf()
    {
        var client = await CreateOwnerClientAsync();
        var quotation = await CreateQuotationAsync(client, new
        {
            items = new[] { new { description = "Printed quote line", quantity = 2, unitPrice = 75000L } },
        });

        var response = await client.GetAsync($"/api/quotations/{quotation.Id}/pdf");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal("application/pdf", response.Content.Headers.ContentType?.MediaType);

        var bytes = await response.Content.ReadAsByteArrayAsync();
        Assert.True(bytes.Length > 1500, $"PDF suspiciously small: {bytes.Length} bytes");
        Assert.Equal("%PDF-", Encoding.ASCII.GetString(bytes, 0, 5));

        var refreshed = await client.GetFromJsonAsync<QuotationDto>($"/api/quotations/{quotation.Id}", JsonOptions);
        Assert.True(refreshed!.HasPdf);
    }

    [Fact]
    public async Task CreateQuotation_WithoutItems_Returns400()
    {
        var client = await CreateOwnerClientAsync();

        var response = await client.PostAsJsonAsync("/api/quotations", new { items = Array.Empty<object>() });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task DeleteQuotation_SoftDeletes_AndHidesFromList()
    {
        var client = await CreateOwnerClientAsync();
        var quotation = await CreateQuotationAsync(client, new
        {
            items = new[] { new { description = "Temp", quantity = 1, unitPrice = 100L } },
        });

        var delete = await client.DeleteAsync($"/api/quotations/{quotation.Id}");
        Assert.Equal(HttpStatusCode.NoContent, delete.StatusCode);

        Assert.Equal(HttpStatusCode.NotFound,
            (await client.GetAsync($"/api/quotations/{quotation.Id}")).StatusCode);
    }

    [Fact]
    public async Task GetQuotations_FiltersByStatus()
    {
        var client = await CreateOwnerClientAsync();
        var draft = await CreateQuotationAsync(client, new
        {
            items = new[] { new { description = "Draft one", quantity = 1, unitPrice = 100L } },
        });
        await CreateQuotationAsync(client, new
        {
            status = "Sent",
            items = new[] { new { description = "Sent one", quantity = 1, unitPrice = 100L } },
        });

        var sent = await GetQuotationsAsync(client, "status=Sent");
        Assert.All(sent, q => Assert.Equal(QuotationStatus.Sent, q.Status));
        Assert.DoesNotContain(sent, q => q.Id == draft.Id);
    }

    [Fact]
    public async Task OtherBusiness_CannotSeeQuotation_Returns404()
    {
        var ownerA = await CreateOwnerClientAsync();
        var quotationA = await CreateQuotationAsync(ownerA, new
        {
            items = new[] { new { description = "Private", quantity = 1, unitPrice = 100L } },
        });

        var ownerB = await CreateOwnerClientAsync();

        Assert.Equal(HttpStatusCode.NotFound,
            (await ownerB.GetAsync($"/api/quotations/{quotationA.Id}")).StatusCode);
        Assert.DoesNotContain(await GetQuotationsAsync(ownerB), q => q.Id == quotationA.Id);
    }

    // --- helpers ---

    private static async Task<QuotationDto> CreateQuotationAsync(HttpClient client, object body)
    {
        var response = await client.PostAsJsonAsync("/api/quotations", body);
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<QuotationDto>(JsonOptions))!;
    }

    private static async Task<List<QuotationDto>> GetQuotationsAsync(HttpClient client, string? query = null)
    {
        var url = "/api/quotations?pageSize=100" + (query is null ? "" : "&" + query);
        var page = await client.GetFromJsonAsync<PagedResult<QuotationDto>>(url, JsonOptions);
        return page!.Data.ToList();
    }

    private static async Task<ProductDto> CreateProductAsync(
        HttpClient client, long sellingPrice, double openingQuantity)
    {
        var response = await client.PostAsJsonAsync("/api/products", new
        {
            name = $"P {Guid.NewGuid():n}",
            sellingPrice,
            openingQuantity,
        });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<ProductDto>(JsonOptions))!;
    }

    private static async Task<CustomerDto> CreateCustomerAsync(HttpClient client)
    {
        var response = await client.PostAsJsonAsync("/api/customers", new
        {
            name = $"C {Guid.NewGuid():n}",
        });
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
