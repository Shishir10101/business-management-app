using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using Khata.Application.DTOs;
using Khata.Tests.Testing;
using Xunit;

namespace Khata.Tests.Integration;

/// <summary>Payment methods: seeded defaults, CRUD, the single-default rule, and guards.</summary>
[Collection(ApiTestCollection.Name)]
public class PaymentMethodEndpointsTests
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web)
    {
        Converters = { new JsonStringEnumConverter() },
    };

    private readonly KhataApiFactory _factory;

    public PaymentMethodEndpointsTests(KhataApiFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task Defaults_AreSeeded_ForANewBusiness()
    {
        var client = await CreateOwnerClientAsync();

        var methods = await GetMethodsAsync(client);

        Assert.Equal(5, methods.Count);
        Assert.Contains(methods, m => m.Name == "Cash" && m.IsDefault && m.Code == "cash");
        Assert.Contains(methods, m => m.Name == "eSewa");
        Assert.Single(methods, m => m.IsDefault);
    }

    [Fact]
    public async Task CreateMethod_Returns201()
    {
        var client = await CreateOwnerClientAsync();

        var response = await client.PostAsJsonAsync("/api/payment-methods", new
        {
            name = "Fonepay",
            code = "fonepay",
            description = "QR payments",
        });

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var method = await response.Content.ReadFromJsonAsync<PaymentMethodDto>(JsonOptions);
        Assert.Equal("Fonepay", method!.Name);
        Assert.Equal("fonepay", method.Code);
        Assert.True(method.IsActive);
    }

    [Fact]
    public async Task CreateMethod_WithDuplicateName_Returns409()
    {
        var client = await CreateOwnerClientAsync();

        var response = await client.PostAsJsonAsync("/api/payment-methods", new { name = "Cash" });

        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
    }

    [Fact]
    public async Task CreateMethod_WithEmptyName_Returns400()
    {
        var client = await CreateOwnerClientAsync();

        var response = await client.PostAsJsonAsync("/api/payment-methods", new { name = "" });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task UpdateMethod_ChangesFields()
    {
        var client = await CreateOwnerClientAsync();
        var method = await CreateMethodAsync(client, "Wallet");

        var response = await client.PutAsJsonAsync($"/api/payment-methods/{method.Id}", new
        {
            name = "Wallet (IME Pay)",
            code = "imepay",
            isActive = false,
            isDefault = false,
        });
        response.EnsureSuccessStatusCode();
        var updated = await response.Content.ReadFromJsonAsync<PaymentMethodDto>(JsonOptions);

        Assert.Equal("Wallet (IME Pay)", updated!.Name);
        Assert.Equal("imepay", updated.Code);
        Assert.False(updated.IsActive);
    }

    [Fact]
    public async Task SettingDefault_ClearsOtherDefaults()
    {
        var client = await CreateOwnerClientAsync();
        var methods = await GetMethodsAsync(client);
        var bank = methods.First(m => m.Name == "Bank Transfer");

        var response = await client.PutAsJsonAsync($"/api/payment-methods/{bank.Id}", new
        {
            name = bank.Name,
            code = bank.Code,
            isActive = true,
            isDefault = true,
        });
        response.EnsureSuccessStatusCode();

        var after = await GetMethodsAsync(client);
        Assert.Single(after, m => m.IsDefault);
        Assert.True(after.First(m => m.Name == "Bank Transfer").IsDefault);
        Assert.False(after.First(m => m.Name == "Cash").IsDefault);
    }

    [Fact]
    public async Task DeleteMethod_SoftDeletes_AndHidesFromList()
    {
        var client = await CreateOwnerClientAsync();
        var method = await CreateMethodAsync(client, "Temp Method");

        var delete = await client.DeleteAsync($"/api/payment-methods/{method.Id}");
        Assert.Equal(HttpStatusCode.NoContent, delete.StatusCode);

        var get = await client.GetAsync($"/api/payment-methods/{method.Id}");
        Assert.Equal(HttpStatusCode.NotFound, get.StatusCode);

        Assert.DoesNotContain(await GetMethodsAsync(client), m => m.Id == method.Id);
    }

    [Fact]
    public async Task DeleteLastMethod_Returns422()
    {
        var client = await CreateOwnerClientAsync();

        var methods = await GetMethodsAsync(client);
        foreach (var method in methods.Take(methods.Count - 1))
        {
            var delete = await client.DeleteAsync($"/api/payment-methods/{method.Id}");
            Assert.Equal(HttpStatusCode.NoContent, delete.StatusCode);
        }

        var remaining = await GetMethodsAsync(client);
        var last = Assert.Single(remaining);

        var response = await client.DeleteAsync($"/api/payment-methods/{last.Id}");
        Assert.Equal(HttpStatusCode.UnprocessableEntity, response.StatusCode);
    }

    [Fact]
    public async Task OtherBusiness_CannotSeeMethod_Returns404()
    {
        var ownerA = await CreateOwnerClientAsync();
        var methodA = await CreateMethodAsync(ownerA, "Private Method");

        var ownerB = await CreateOwnerClientAsync();

        var get = await ownerB.GetAsync($"/api/payment-methods/{methodA.Id}");
        Assert.Equal(HttpStatusCode.NotFound, get.StatusCode);
    }

    // --- helpers ---

    private static async Task<PaymentMethodDto> CreateMethodAsync(HttpClient client, string name)
    {
        var response = await client.PostAsJsonAsync("/api/payment-methods", new { name });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<PaymentMethodDto>(JsonOptions))!;
    }

    private static async Task<List<PaymentMethodDto>> GetMethodsAsync(HttpClient client)
        => (await client.GetFromJsonAsync<List<PaymentMethodDto>>("/api/payment-methods", JsonOptions))!;

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
