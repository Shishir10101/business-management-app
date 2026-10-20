using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Tests.Testing;
using Xunit;

namespace Khata.Tests.Integration;

/// <summary>
/// Hostile / degenerate input must produce a 4xx with a readable reason — never
/// a 500. Every case here was found by probing the API rather than by following
/// the happy path, so these are the regression tests for those findings.
/// </summary>
[Collection(ApiTestCollection.Name)]
public class RobustnessTests
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web)
    {
        Converters = { new JsonStringEnumConverter() },
    };

    private readonly KhataApiFactory _factory;

    public RobustnessTests(KhataApiFactory factory)
    {
        _factory = factory;
    }

    // --- CSV import: missing / null payloads ---
    //
    // .NET 10 rejects a null for a non-nullable record member during binding, so
    // the request never reaches the importer — which is the desired outcome.
    // These tests pin that down: a bad body must be a 400, never a 500.

    [Fact]
    public async Task Import_WithNullCsv_IsABadRequestNotA500()
    {
        var client = await CreateOwnerClientAsync();

        var response = await client.PostAsJsonAsync(
            "/api/import/products", new { csv = (string?)null });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.Contains("csv", body, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task Preview_WithNullCsv_IsABadRequestNotA500()
    {
        var client = await CreateOwnerClientAsync();

        var response = await client.PostAsJsonAsync(
            "/api/import/customers/preview", new { csv = (string?)null });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task Import_WithOnlyUnknownColumns_ExplainsTheMissingNameColumn()
    {
        var client = await CreateOwnerClientAsync();

        var response = await client.PostAsJsonAsync("/api/import/products",
            new { csv = "colour,size\nred,L\n" });

        Assert.Equal(HttpStatusCode.UnprocessableEntity, response.StatusCode);
        var preview = await response.Content.ReadFromJsonAsync<ImportPreviewDto>(JsonOptions);
        var issue = Assert.Single(preview!.Issues);
        Assert.Equal("name", issue.Column);
        Assert.Contains("name column", issue.Message);
    }

    [Fact]
    public async Task Import_WithAnOversizedAmount_ReportsARowError()
    {
        var client = await CreateOwnerClientAsync();
        var suffix = Guid.NewGuid().ToString("n")[..8];

        var csv = "name,costPrice\n" + $"Huge {suffix},999999999999999999999999999\n";

        var response = await client.PostAsJsonAsync("/api/import/products", new { csv });

        Assert.Equal(HttpStatusCode.UnprocessableEntity, response.StatusCode);
        var preview = await response.Content.ReadFromJsonAsync<ImportPreviewDto>(JsonOptions);
        Assert.Equal(1, preview!.InvalidRows);
        Assert.Equal("costPrice", Assert.Single(preview.Issues).Column);
    }

    [Fact]
    public async Task Import_WithMoreRowsThanTheLimit_IsRefusedWithTheCount()
    {
        var client = await CreateOwnerClientAsync();

        var builder = new StringBuilder("name\n");
        for (var i = 0; i < 5_001; i++) builder.Append($"Item {i}\n");

        var response = await client.PostAsJsonAsync("/api/import/products",
            new { csv = builder.ToString() });

        Assert.Equal(HttpStatusCode.UnprocessableEntity, response.StatusCode);
        var preview = await response.Content.ReadFromJsonAsync<ImportPreviewDto>(JsonOptions);
        Assert.Contains("5000", Assert.Single(preview!.Issues).Message);
    }

    // --- Paging ---

    [Fact]
    public async Task Products_WithZeroPageAndPageSize_ReturnsAUsableFirstPage()
    {
        var client = await CreateOwnerClientAsync();

        var page = await client.GetFromJsonAsync<PagedResult<ProductDto>>(
            "/api/products?page=0&pageSize=0", JsonOptions);

        Assert.NotNull(page);
        Assert.Equal(1, page!.Pagination.Page);
        Assert.Equal(1, page.Pagination.PageSize);
        Assert.False(page.Pagination.HasPrev);
    }

    [Fact]
    public async Task Products_WithHugePageSize_IsClamped()
    {
        var client = await CreateOwnerClientAsync();

        var page = await client.GetFromJsonAsync<PagedResult<ProductDto>>(
            "/api/products?pageSize=100000", JsonOptions);

        Assert.Equal(100, page!.Pagination.PageSize);
    }

    [Fact]
    public async Task CustomerLedger_WithZeroPage_IsHandled()
    {
        var client = await CreateOwnerClientAsync();
        var customer = await CreateCustomerAsync(client);

        var ledger = await client.GetFromJsonAsync<PartyLedgerDto>(
            $"/api/customers/{customer.Id}/ledger?page=0&pageSize=0", JsonOptions);

        Assert.NotNull(ledger);
        Assert.True(ledger!.Pagination.Page >= 1);
        Assert.True(ledger.Pagination.PageSize >= 1);
    }

    // --- Auth ---

    [Fact]
    public async Task GarbageBearerToken_IsUnauthorized()
    {
        var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", "not-a-jwt");

        var response = await client.GetAsync("/api/products");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Import_WithoutABusiness_IsForbidden()
    {
        // A fresh user with no business: no membership means no permissions, so
        // the policy denies it (403 — authenticated, not allowed) rather than
        // 401. Either way it must never reach the importer.
        var client = await AuthEndpointsTests.CreateAuthenticatedClientAsync(_factory);

        var response = await client.PostAsJsonAsync("/api/import/products",
            new { csv = "name\nRice\n" });

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    // --- helpers ---

    private static async Task<CustomerDto> CreateCustomerAsync(HttpClient client)
    {
        var response = await client.PostAsJsonAsync("/api/customers", new
        {
            name = $"Ledger {Guid.NewGuid():n}",
            openingBalance = 50000,
        });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<CustomerDto>(JsonOptions))!;
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
