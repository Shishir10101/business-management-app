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
/// Invoices: standalone creation with its own numbering, generation from a sale,
/// totals math, draft-only editing, PDF rendering, and isolation.
/// </summary>
[Collection(ApiTestCollection.Name)]
public class InvoiceEndpointsTests
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web)
    {
        Converters = { new JsonStringEnumConverter() },
    };

    private readonly KhataApiFactory _factory;

    public InvoiceEndpointsTests(KhataApiFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task CreateStandaloneInvoice_AllocatesNumber_AndComputesTotals()
    {
        var client = await CreateOwnerClientAsync();
        var customer = await CreateCustomerAsync(client);

        var invoice = await CreateInvoiceAsync(client, new
        {
            customerId = customer.Id,
            items = new[]
            {
                new { description = "Basmati Rice 5kg", quantity = 2, unitPrice = 110000L, discountAmount = 5000L, taxRateBps = 1300 },
                new { description = "Delivery charge", quantity = 1, unitPrice = 5000L, discountAmount = 0L, taxRateBps = 0 },
            },
        });

        Assert.Equal("INV-00001", invoice.InvoiceNumber);
        Assert.Equal(InvoiceStatus.Draft, invoice.Status);
        Assert.Equal(customer.Name, invoice.CustomerName);
        Assert.Equal(2, invoice.Items.Count);

        // gross 220000 + 5000 = 225000; line discount 5000; tax = 13% of 215000 = 27950
        Assert.Equal(225000, invoice.Subtotal);
        Assert.Equal(5000, invoice.DiscountAmount);
        Assert.Equal(27950, invoice.TaxAmount);
        Assert.Equal(247950, invoice.TotalAmount);
        Assert.False(invoice.HasPdf);
    }

    [Fact]
    public async Task CreateInvoiceFromSale_CopiesLines_AndReusesTheSaleNumber()
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, sellingPrice: 10000, openingQuantity: 20);
        var customer = await CreateCustomerAsync(client);
        var sale = await CreateSaleAsync(client, customer.Id, product.Id, quantity: 3, unitPrice: 10000);

        var invoice = await CreateInvoiceAsync(client, new { saleId = sale.Id });

        Assert.Equal(sale.InvoiceNumber, invoice.InvoiceNumber);
        Assert.Equal(sale.Id, invoice.SaleId);
        Assert.Equal(sale.TotalAmount, invoice.TotalAmount);
        Assert.Equal(sale.Subtotal, invoice.Subtotal);
        Assert.Equal(customer.Id, invoice.CustomerId);
        Assert.Single(invoice.Items);
        Assert.Equal("Sale product", invoice.Items[0].Description);
    }

    [Fact]
    public async Task CreateInvoiceFromTheSameSaleTwice_Returns409()
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, 10000, 20);
        var customer = await CreateCustomerAsync(client);
        var sale = await CreateSaleAsync(client, customer.Id, product.Id, 1, 10000);

        await CreateInvoiceAsync(client, new { saleId = sale.Id });

        var response = await client.PostAsJsonAsync("/api/invoices", new { saleId = sale.Id });
        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
    }

    [Fact]
    public async Task InvoiceNumbers_ContinueTheSharedSeriesAfterSales()
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, 1000, 50);
        var customer = await CreateCustomerAsync(client);

        // Two sales consume INV-00001 and INV-00002.
        await CreateSaleAsync(client, customer.Id, product.Id, 1, 1000);
        await CreateSaleAsync(client, customer.Id, product.Id, 1, 1000);

        // A standalone invoice takes the next number in the same series.
        var invoice = await CreateInvoiceAsync(client, new
        {
            items = new[] { new { description = "Consulting", quantity = 1, unitPrice = 500000L } },
        });

        Assert.Equal("INV-00003", invoice.InvoiceNumber);
    }

    [Fact]
    public async Task UpdateDraftInvoice_ReplacesTheLines()
    {
        var client = await CreateOwnerClientAsync();
        var invoice = await CreateInvoiceAsync(client, new
        {
            items = new[] { new { description = "Old line", quantity = 1, unitPrice = 1000L } },
        });

        var response = await client.PutAsJsonAsync($"/api/invoices/{invoice.Id}", new
        {
            items = new[]
            {
                new { description = "New line A", quantity = 2, unitPrice = 2500L },
                new { description = "New line B", quantity = 1, unitPrice = 500L },
            },
        });
        response.EnsureSuccessStatusCode();
        var updated = await response.Content.ReadFromJsonAsync<InvoiceDto>(JsonOptions);

        Assert.Equal(2, updated!.Items.Count);
        Assert.Equal(5500, updated.Subtotal);
        Assert.Equal(5500, updated.TotalAmount);
        Assert.DoesNotContain(updated.Items, i => i.Description == "Old line");
    }

    [Fact]
    public async Task UpdateIssuedInvoice_Returns422()
    {
        var client = await CreateOwnerClientAsync();
        var invoice = await CreateInvoiceAsync(client, new
        {
            status = "Sent",
            items = new[] { new { description = "Line", quantity = 1, unitPrice = 1000L } },
        });

        var response = await client.PutAsJsonAsync($"/api/invoices/{invoice.Id}", new
        {
            items = new[] { new { description = "Changed", quantity = 1, unitPrice = 1000L } },
        });

        Assert.Equal(HttpStatusCode.UnprocessableEntity, response.StatusCode);
    }

    [Fact]
    public async Task InvoicePdf_RendersAWellFormedPdf()
    {
        var client = await CreateOwnerClientAsync();
        var invoice = await CreateInvoiceAsync(client, new
        {
            items = new[] { new { description = "Printed line", quantity = 2, unitPrice = 15000L } },
        });

        var response = await client.GetAsync($"/api/invoices/{invoice.Id}/pdf");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal("application/pdf", response.Content.Headers.ContentType?.MediaType);
        Assert.Equal($"{invoice.InvoiceNumber}.pdf",
            response.Content.Headers.ContentDisposition?.FileName?.Trim('"'));

        var bytes = await response.Content.ReadAsByteArrayAsync();
        Assert.True(bytes.Length > 1500, $"PDF suspiciously small: {bytes.Length} bytes");
        Assert.Equal("%PDF-", Encoding.ASCII.GetString(bytes, 0, 5));

        // Generating a PDF is remembered on the invoice.
        var refreshed = await client.GetFromJsonAsync<InvoiceDto>($"/api/invoices/{invoice.Id}", JsonOptions);
        Assert.True(refreshed!.HasPdf);
        Assert.NotNull(refreshed.PdfGeneratedAt);
    }

    [Fact]
    public async Task CreateInvoice_WithoutItemsOrSale_Returns400()
    {
        var client = await CreateOwnerClientAsync();

        var response = await client.PostAsJsonAsync("/api/invoices", new { items = Array.Empty<object>() });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task CreateInvoice_WithNonPositiveQuantity_Returns400()
    {
        var client = await CreateOwnerClientAsync();

        var response = await client.PostAsJsonAsync("/api/invoices", new
        {
            items = new[] { new { description = "Zero", quantity = 0, unitPrice = 1000L } },
        });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task DeleteInvoice_SoftDeletes_AndHidesFromList()
    {
        var client = await CreateOwnerClientAsync();
        var invoice = await CreateInvoiceAsync(client, new
        {
            items = new[] { new { description = "Temp", quantity = 1, unitPrice = 100L } },
        });

        var delete = await client.DeleteAsync($"/api/invoices/{invoice.Id}");
        Assert.Equal(HttpStatusCode.NoContent, delete.StatusCode);

        var get = await client.GetAsync($"/api/invoices/{invoice.Id}");
        Assert.Equal(HttpStatusCode.NotFound, get.StatusCode);
    }

    [Fact]
    public async Task GetInvoices_FiltersByStatusAndSearch()
    {
        var client = await CreateOwnerClientAsync();
        var suffix = Guid.NewGuid().ToString("n")[..8];
        var customer = await CreateCustomerAsync(client, name: $"Searchable {suffix}");

        var draft = await CreateInvoiceAsync(client, new
        {
            customerId = customer.Id,
            items = new[] { new { description = "A", quantity = 1, unitPrice = 100L } },
        });
        await CreateInvoiceAsync(client, new
        {
            status = "Sent",
            items = new[] { new { description = "B", quantity = 1, unitPrice = 100L } },
        });

        var drafts = await GetInvoicesAsync(client, "status=Draft");
        Assert.Contains(drafts, i => i.Id == draft.Id);
        Assert.All(drafts, i => Assert.Equal(InvoiceStatus.Draft, i.Status));

        var bySearch = await GetInvoicesAsync(client, $"search={suffix}");
        Assert.Single(bySearch);
        Assert.Equal(draft.Id, bySearch[0].Id);

        var byNumber = await GetInvoicesAsync(client, $"search={draft.InvoiceNumber}");
        Assert.Contains(byNumber, i => i.Id == draft.Id);
    }

    [Fact]
    public async Task OtherBusiness_CannotSeeInvoice_OrItsPdf_Returns404()
    {
        var ownerA = await CreateOwnerClientAsync();
        var invoiceA = await CreateInvoiceAsync(ownerA, new
        {
            items = new[] { new { description = "Private", quantity = 1, unitPrice = 100L } },
        });

        var ownerB = await CreateOwnerClientAsync();

        Assert.Equal(HttpStatusCode.NotFound, (await ownerB.GetAsync($"/api/invoices/{invoiceA.Id}")).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await ownerB.GetAsync($"/api/invoices/{invoiceA.Id}/pdf")).StatusCode);
        Assert.DoesNotContain(await GetInvoicesAsync(ownerB), i => i.Id == invoiceA.Id);
    }

    // --- helpers ---

    private static async Task<InvoiceDto> CreateInvoiceAsync(HttpClient client, object body)
    {
        var response = await client.PostAsJsonAsync("/api/invoices", body);
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<InvoiceDto>(JsonOptions))!;
    }

    private static async Task<List<InvoiceDto>> GetInvoicesAsync(HttpClient client, string? query = null)
    {
        var url = "/api/invoices?pageSize=100" + (query is null ? "" : "&" + query);
        var page = await client.GetFromJsonAsync<PagedResult<InvoiceDto>>(url, JsonOptions);
        return page!.Data.ToList();
    }

    private static async Task<SaleDto> CreateSaleAsync(
        HttpClient client, long customerId, long productId, decimal quantity, long unitPrice)
    {
        var response = await client.PostAsJsonAsync("/api/sales", new
        {
            customerId,
            saleType = "Cash",
            items = new[] { new { productId, quantity, unitPrice } },
            paidAmount = (long)Math.Round(quantity * unitPrice),
        });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<SaleDto>(JsonOptions))!;
    }

    private static async Task<ProductDto> CreateProductAsync(
        HttpClient client, long sellingPrice, double openingQuantity)
    {
        var response = await client.PostAsJsonAsync("/api/products", new
        {
            name = "Sale product",
            sellingPrice,
            openingQuantity,
        });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<ProductDto>(JsonOptions))!;
    }

    private static async Task<CustomerDto> CreateCustomerAsync(HttpClient client, string? name = null)
    {
        var response = await client.PostAsJsonAsync("/api/customers", new
        {
            name = name ?? $"C {Guid.NewGuid():n}",
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
