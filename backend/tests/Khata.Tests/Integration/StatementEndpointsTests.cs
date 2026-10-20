using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using Khata.Application.DTOs;
using Khata.Tests.Testing;
using Xunit;

namespace Khata.Tests.Integration;

/// <summary>
/// Signed public statement links: minting, rendering, expiry and tamper resistance.
/// </summary>
[Collection(ApiTestCollection.Name)]
public class StatementEndpointsTests
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web)
    {
        Converters = { new JsonStringEnumConverter() },
    };

    private readonly KhataApiFactory _factory;

    public StatementEndpointsTests(KhataApiFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task MintLink_ReturnsAUrlWithToken()
    {
        var client = await CreateOwnerClientAsync();
        var customer = await CreateCustomerAsync(client, "Link Customer");

        var response = await client.PostAsJsonAsync(
            $"/api/customers/{customer.Id}/statement-link", new { });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var result = await response.Content.ReadFromJsonAsync<StatementLinkResponse>(JsonOptions);
        Assert.NotNull(result);
        Assert.NotNull(result.Url);
        Assert.Contains("/s/", result.Url);
        Assert.True(result.ExpiresAt > DateTimeOffset.UtcNow);
    }

    [Fact]
    public async Task PublicStatement_ShowsCustomerLedgerHtml()
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, 1000, 2000, 0, 100);
        var customer = await CreateCustomerAsync(client, "Public Customer");
        await CreateSaleAsync(client, customer.Id, product.Id, 2, 2000);

        var mint = await client.PostAsJsonAsync(
            $"/api/customers/{customer.Id}/statement-link", new { });
        var link = (await mint.Content.ReadFromJsonAsync<StatementLinkResponse>(JsonOptions))!;

        // Anonymous client — no auth header.
        var anon = _factory.CreateClient();
        var htmlResponse = await anon.GetAsync(link.Url);

        Assert.Equal(HttpStatusCode.OK, htmlResponse.StatusCode);
        Assert.Equal("text/html", htmlResponse.Content.Headers.ContentType?.MediaType);

        var html = await htmlResponse.Content.ReadAsStringAsync();
        Assert.Contains("Public Customer", html);
        Assert.Contains("40.00", html); // 2 × 2000 paisa = Rs 40.00
    }

    [Fact]
    public async Task PublicStatement_ExpiredToken_Returns401()
    {
        var client = await CreateOwnerClientAsync();
        var customer = await CreateCustomerAsync(client);

        var mint = await client.PostAsJsonAsync(
            $"/api/customers/{customer.Id}/statement-link?ttlDays=-1", new { });
        var link = (await mint.Content.ReadFromJsonAsync<StatementLinkResponse>(JsonOptions))!;

        var anon = _factory.CreateClient();
        var response = await anon.GetAsync(link.Url);
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task PublicStatement_TamperedToken_Returns401()
    {
        var client = await CreateOwnerClientAsync();
        var customer = await CreateCustomerAsync(client);

        var mint = await client.PostAsJsonAsync(
            $"/api/customers/{customer.Id}/statement-link", new { });
        var link = (await mint.Content.ReadFromJsonAsync<StatementLinkResponse>(JsonOptions))!;

        var tampered = link.Url + "x";
        var anon = _factory.CreateClient();
        var response = await anon.GetAsync(tampered);
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task PublicStatement_IsolatesByBusiness()
    {
        var ownerA = await CreateOwnerClientAsync();
        var customerA = await CreateCustomerAsync(ownerA, "A Customer");
        var mintA = await ownerA.PostAsJsonAsync(
            $"/api/customers/{customerA.Id}/statement-link", new { });
        var linkA = (await mintA.Content.ReadFromJsonAsync<StatementLinkResponse>(JsonOptions))!;

        // Owner B should not be able to derive a valid token for customer A,
        // but the real isolation test is that the HTML does not leak A's data
        // to an unauthenticated caller who somehow guesses a token.
        var anon = _factory.CreateClient();
        var htmlResponse = await anon.GetAsync(linkA.Url);
        Assert.Equal(HttpStatusCode.OK, htmlResponse.StatusCode);

        var html = await htmlResponse.Content.ReadAsStringAsync();
        Assert.Contains("A Customer", html);

        // Now create owner B with a different customer and ensure the token
        // for A still works (it should, because the token is self-contained).
        var ownerB = await CreateOwnerClientAsync();
        var customerB = await CreateCustomerAsync(ownerB, "B Customer");
        var mintB = await ownerB.PostAsJsonAsync(
            $"/api/customers/{customerB.Id}/statement-link", new { });
        var linkB = (await mintB.Content.ReadFromJsonAsync<StatementLinkResponse>(JsonOptions))!;

        var htmlB = await (await anon.GetAsync(linkB.Url)).Content.ReadAsStringAsync();
        Assert.Contains("B Customer", htmlB);
        Assert.DoesNotContain("A Customer", htmlB);
    }

    // --- helpers (same pattern as ReportEndpointsTests) ---

    private static async Task<ProductDto> CreateProductAsync(
        HttpClient client, long costPrice, long sellingPrice, int taxRateBps,
        double openingQuantity, string? name = null, double minQuantity = 0)
    {
        var response = await client.PostAsJsonAsync("/api/products", new
        {
            name = name ?? $"P {Guid.NewGuid():n}",
            costPrice,
            sellingPrice,
            taxRateBps,
            openingQuantity,
            minQuantity,
        });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<ProductDto>(JsonOptions))!;
    }

    private static async Task<CustomerDto> CreateCustomerAsync(
        HttpClient client, string? name = null, long openingBalance = 0)
    {
        var response = await client.PostAsJsonAsync("/api/customers", new
        {
            name = name ?? $"C {Guid.NewGuid():n}",
            openingBalance,
        });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<CustomerDto>(JsonOptions))!;
    }

    private static async Task<SaleDto> CreateSaleAsync(
        HttpClient client, long customerId, long productId, decimal quantity, long unitPrice)
    {
        var response = await client.PostAsJsonAsync("/api/sales", new
        {
            customerId,
            saleType = "Credit",
            items = new[] { new { productId, quantity, unitPrice } },
            paidAmount = 0L,
        });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<SaleDto>(JsonOptions))!;
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

public record StatementLinkResponse(string Url, DateTimeOffset ExpiresAt);
