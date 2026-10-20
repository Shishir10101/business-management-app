using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Tests.Testing;
using Xunit;

namespace Khata.Tests.Integration;

/// <summary>
/// CSV import of products and customers: preview counts, per-row validation,
/// all-or-nothing refusal, duplicate skipping, category/unit resolution and the
/// khata entry an opening balance must produce.
/// </summary>
[Collection(ApiTestCollection.Name)]
public class ImportEndpointsTests
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web)
    {
        Converters = { new JsonStringEnumConverter() },
    };

    private readonly KhataApiFactory _factory;

    public ImportEndpointsTests(KhataApiFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task Preview_CountsRows_AndImportCreatesThemWithParsedAmounts()
    {
        var client = await CreateOwnerClientAsync();
        var suffix = NewSuffix();

        // Rupee amounts with thousands separators, a percentage tax rate, and a
        // quoted field containing a comma — the shapes Excel actually produces.
        var csv =
            "name,costPrice,sellingPrice,taxRate,openingQuantity\n" +
            $"\"Rice {suffix}\",\"Rs 1,234.50\",1300,13,10\n" +
            $"Oil {suffix},200,250,0,5\n";

        var preview = await PreviewAsync(client, "products", csv);
        Assert.Equal(2, preview.TotalRows);
        Assert.Equal(2, preview.ValidRows);
        Assert.Equal(0, preview.InvalidRows);
        Assert.Empty(preview.IgnoredColumns);

        var result = await ImportAsync(client, "products", csv);
        Assert.Equal(2, result.Created);
        Assert.Equal(0, result.Skipped);

        var products = await GetProductsAsync(client, $"Rice {suffix}");
        var rice = Assert.Single(products);
        Assert.Equal(123450, rice.CostPrice);      // रु 1,234.50
        Assert.Equal(130000, rice.SellingPrice);   // रु 1,300.00
        Assert.Equal(1300, rice.TaxRateBps);       // 13%
        Assert.Equal(10m, rice.StockQuantity);
    }

    [Fact]
    public async Task InvalidRow_RefusesTheWholeFile_AndWritesNothing()
    {
        var client = await CreateOwnerClientAsync();
        var suffix = NewSuffix();

        var csv =
            "name,sellingPrice\n" +
            $",100\n" +                                  // row 2: no name
            $"Good {suffix},12x\n" +                     // row 3: not a number
            $"Also {suffix},300\n";                      // row 4: fine

        var preview = await PreviewAsync(client, "products", csv);
        Assert.Equal(3, preview.TotalRows);
        Assert.Equal(1, preview.ValidRows);
        Assert.Equal(2, preview.InvalidRows);
        Assert.Contains(preview.Issues, i => i.Row == 2 && i.Column == "name");
        Assert.Contains(preview.Issues, i => i.Row == 3 && i.Column == "sellingPrice");

        var response = await client.PostAsJsonAsync("/api/import/products", new { csv });
        Assert.Equal(HttpStatusCode.UnprocessableEntity, response.StatusCode);
        var rejected = await response.Content.ReadFromJsonAsync<ImportPreviewDto>(JsonOptions);
        Assert.Equal(2, rejected!.InvalidRows);

        // Not one row was written — the good row included.
        Assert.Empty(await GetProductsAsync(client, suffix));
    }

    [Fact]
    public async Task Import_CreatesMissingCategory_AndMatchesUnitByShortName()
    {
        var client = await CreateOwnerClientAsync();
        var suffix = NewSuffix();
        var category = $"Snacks {suffix}";

        var csv =
            "name,category,unit\n" +
            $"Chips {suffix},{category},kg\n";

        var result = await ImportAsync(client, "products", csv);
        Assert.Equal(1, result.Created);

        var product = Assert.Single(await GetProductsAsync(client, $"Chips {suffix}"));
        Assert.Equal(category, product.CategoryName);
        Assert.Equal("kg", product.UnitShortName);
    }

    [Fact]
    public async Task UnknownUnit_RefusesTheFile()
    {
        var client = await CreateOwnerClientAsync();
        var suffix = NewSuffix();

        var csv = "name,unit\n" + $"Loose {suffix},packet\n";

        var preview = await PreviewAsync(client, "products", csv);
        Assert.Equal(1, preview.InvalidRows);
        var issue = Assert.Single(preview.Issues);
        Assert.Equal("unit", issue.Column);
        Assert.Contains("Unknown unit", issue.Message);
    }

    [Fact]
    public async Task Import_SkipsRowsThatAlreadyExist_SoARerunIsSafe()
    {
        var client = await CreateOwnerClientAsync();
        var suffix = NewSuffix();

        var csv =
            "name,sku,barcode,sellingPrice\n" +
            $"Tea {suffix},TEA-{suffix},BAR-TEA-{suffix},120\n" +
            $"Coffee {suffix},COF-{suffix},BAR-COF-{suffix},220\n";

        var first = await ImportAsync(client, "products", csv);
        Assert.Equal(2, first.Created);

        // The rerun must skip its own rows — including their barcodes, which
        // are unique per business and would otherwise look like a conflict.
        var second = await ImportAsync(client, "products", csv);
        Assert.Equal(0, second.Created);
        Assert.Equal(2, second.Skipped);

        // Still exactly two products — nothing was duplicated.
        Assert.Equal(2, (await GetProductsAsync(client, suffix)).Count);
    }

    [Fact]
    public async Task BarcodeUsedByAnotherProduct_IsARowError_NotAServerError()
    {
        var client = await CreateOwnerClientAsync();
        var suffix = NewSuffix();

        await ImportAsync(client, "products",
            $"name,barcode\nFirst {suffix},BAR-{suffix}\n");

        var preview = await PreviewAsync(client, "products",
            $"name,barcode\nSecond {suffix},BAR-{suffix}\n");

        Assert.Equal(1, preview.InvalidRows);
        var issue = Assert.Single(preview.Issues);
        Assert.Equal("barcode", issue.Column);
        Assert.Contains("already used", issue.Message);
    }

    [Fact]
    public async Task ImportCustomers_OpeningBalance_LandsInTheKhata()
    {
        var client = await CreateOwnerClientAsync();
        var suffix = NewSuffix();
        var name = $"Ram {suffix}";

        var csv =
            "name,phone,openingBalance,city\n" +
            $"{name},9841000001,\"1,500.00\",Kathmandu\n";

        var result = await ImportAsync(client, "customers", csv);
        Assert.Equal(1, result.Created);

        var page = await client.GetFromJsonAsync<PagedResult<CustomerDto>>(
            $"/api/customers?search={Uri.EscapeDataString(name)}", JsonOptions);
        var customer = Assert.Single(page!.Data);
        Assert.Equal(150000, customer.CurrentBalance);
        Assert.Equal("Kathmandu", customer.City);

        var ledger = await client.GetFromJsonAsync<PartyLedgerDto>(
            $"/api/customers/{customer.Id}/ledger", JsonOptions);
        Assert.Equal(150000, ledger!.Summary.OpeningBalance);
    }

    [Fact]
    public async Task Preview_ReportsIgnoredColumns_SoNothingIsSilentlyDropped()
    {
        var client = await CreateOwnerClientAsync();
        var suffix = NewSuffix();

        var csv = "name,sellingPrice,colour\n" + $"Pen {suffix},25,blue\n";

        var preview = await PreviewAsync(client, "products", csv);
        Assert.Equal(1, preview.ValidRows);
        Assert.Contains("colour", preview.IgnoredColumns);
        Assert.Contains("name", preview.Columns);
    }

    [Fact]
    public async Task Template_IsACsvFileWithTheExpectedHeaders()
    {
        var client = await CreateOwnerClientAsync();

        var response = await client.GetAsync("/api/import/products/template");
        response.EnsureSuccessStatusCode();
        Assert.Equal("text/csv", response.Content.Headers.ContentType?.MediaType);

        var bytes = await response.Content.ReadAsByteArrayAsync();
        var text = System.Text.Encoding.UTF8.GetString(bytes);
        Assert.StartsWith("name,sku,barcode,category,unit,costPrice", text);
    }

    [Fact]
    public async Task EmptyFile_IsRefusedWithAReadableMessage()
    {
        var client = await CreateOwnerClientAsync();

        var preview = await PreviewAsync(client, "products", "name,sellingPrice\n");
        Assert.Equal(1, preview.InvalidRows);
        Assert.Contains("empty", Assert.Single(preview.Issues).Message);

        var response = await client.PostAsJsonAsync("/api/import/products",
            new { csv = "name,sellingPrice\n" });
        Assert.Equal(HttpStatusCode.UnprocessableEntity, response.StatusCode);
    }

    // --- helpers ---

    private static string NewSuffix() => Guid.NewGuid().ToString("n")[..8];

    private static async Task<ImportPreviewDto> PreviewAsync(HttpClient client, string entity, string csv)
    {
        var response = await client.PostAsJsonAsync($"/api/import/{entity}/preview", new { csv });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<ImportPreviewDto>(JsonOptions))!;
    }

    private static async Task<ImportResultDto> ImportAsync(HttpClient client, string entity, string csv)
    {
        var response = await client.PostAsJsonAsync($"/api/import/{entity}", new { csv });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<ImportResultDto>(JsonOptions))!;
    }

    private static async Task<List<ProductDto>> GetProductsAsync(HttpClient client, string search)
    {
        var page = await client.GetFromJsonAsync<PagedResult<ProductDto>>(
            $"/api/products?search={Uri.EscapeDataString(search)}&pageSize=100", JsonOptions);
        return page!.Data.ToList();
    }

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
