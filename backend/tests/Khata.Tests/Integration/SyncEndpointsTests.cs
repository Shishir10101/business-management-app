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
/// Offline sync protocol: pull deltas, push queued writes, idempotent retries,
/// optimistic-concurrency conflicts, and tenant isolation.
/// </summary>
[Collection(ApiTestCollection.Name)]
public class SyncEndpointsTests
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web)
    {
        Converters = { new JsonStringEnumConverter() },
    };

    private readonly KhataApiFactory _factory;

    public SyncEndpointsTests(KhataApiFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task Pull_WithoutSince_ReturnsEverything()
    {
        var client = await CreateOwnerClientAsync();
        await CreateProductAsync(client, 6000, 1000, 0, 10);
        await CreateCustomerAsync(client, "Kamala");
        await CreateSupplierAsync(client, "Sherpa Suppliers");

        var pull = await PullAsync(client, since: null);

        Assert.False(pull.HasMore);
        Assert.Contains(pull.Changes, c => c.EntityType == "product" && c.ChangeType == "upsert");
        Assert.Contains(pull.Changes, c => c.EntityType == "customer");
        Assert.Contains(pull.Changes, c => c.EntityType == "supplier");

        var customer = pull.Changes.Single(c => c.EntityType == "customer");
        Assert.Contains("Kamala", customer.Payload!.ToString());
    }

    [Fact]
    public async Task Pull_WithSince_ReturnsLaterChanges()
    {
        var client = await CreateOwnerClientAsync();
        await CreateCustomerAsync(client, "Before");
        var first = await PullAsync(client, since: null);

        // Anything created after the first pull must show up in the next one.
        await CreateCustomerAsync(client, "After");

        var second = await PullAsync(client, first.ServerTime);

        var customerChanges = second.Changes.Where(c => c.EntityType == "customer").ToList();
        Assert.Contains(customerChanges, c => c.Payload!.ToString()!.Contains("After"));

        // The delta is not empty, and the first pull never saw the later row.
        Assert.NotEmpty(second.Changes);
        Assert.DoesNotContain(first.Changes, c => c.Payload!.ToString()!.Contains("After"));

        // NOTE: the cursor is deliberately pulled back one second because SQLite
        // stores whole-second precision, so a row created in the same second as
        // the cursor may legitimately repeat. A repeat is idempotent; a miss is
        // data loss — so we always err toward repeating.
    }

    [Fact]
    public async Task Pull_ReportsSoftDeletes()
    {
        var client = await CreateOwnerClientAsync();
        var customer = await CreateCustomerAsync(client, "Doomed");
        var first = await PullAsync(client, since: null);
        Assert.Contains(first.Changes, c => c.EntityType == "customer" && c.ChangeType == "upsert");

        var delete = await client.DeleteAsync($"/api/customers/{customer.Id}");
        Assert.Equal(HttpStatusCode.NoContent, delete.StatusCode);

        var second = await PullAsync(client, first.ServerTime);
        var change = second.Changes.Single(c => c.EntityType == "customer");
        Assert.Equal("deleted", change.ChangeType);
        Assert.Equal(customer.Id, change.EntityId);
    }

    [Fact]
    public async Task Pull_IncludesStockAndLedgerData()
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, 6000, 1000, 0, 10);
        var customer = await CreateCustomerAsync(client, "Buyer");
        await CreateSaleAsync(client, customer.Id, product.Id, 2, 1000);

        var pull = await PullAsync(client, since: null);

        Assert.Contains(pull.Changes, c => c.EntityType == "stock" && c.ChangeType == "upsert");
        Assert.Contains(pull.Changes, c => c.EntityType == "sale" && c.ChangeType == "upsert");
    }

    [Fact]
    public async Task Push_CreatesCustomer_AndReturnsTheServerId()
    {
        var client = await CreateOwnerClientAsync();

        var result = await PushAsync(client, [
            Op("cust-1", "customer", "create", 0, payload: new { name = "Offline Customer" })
        ]);

        var single = Assert.Single(result.Results);
        Assert.Equal("applied", single.Status);
        Assert.NotNull(single.EntityId);
        Assert.True(single.EntityId > 0);

        // The row really exists on the server.
        var fetched = await client.GetFromJsonAsync<CustomerDto>(
            $"/api/customers/{single.EntityId}", JsonOptions);
        Assert.Equal("Offline Customer", fetched!.Name);
    }

    [Fact]
    public async Task Push_IsIdempotent_ForARetriedOperationId()
    {
        var client = await CreateOwnerClientAsync();

        var first = await PushAsync(client, [
            Op("idem-1", "customer", "create", 0, payload: new { name = "Only Once" })
        ]);
        Assert.Equal("applied", first.Results[0].Status);
        var createdId = first.Results[0].EntityId;

        // Same operation id, retried after a lost response.
        var second = await PushAsync(client, [
            Op("idem-1", "customer", "create", 0, payload: new { name = "Only Once" })
        ]);
        Assert.Equal("duplicate", second.Results[0].Status);
        Assert.Equal(createdId, second.Results[0].EntityId);

        var list = await client.GetFromJsonAsync<PagedResult<CustomerDto>>(
            "/api/customers?pageSize=100", JsonOptions);
        Assert.Single(list!.Data);
    }

    [Fact]
    public async Task Push_UpdateWithStaleBase_ReturnsConflict()
    {
        var client = await CreateOwnerClientAsync();
        var customer = await CreateCustomerAsync(client, "Contested");
        var stale = customer.UpdatedAt;

        // The server copy moves on.
        await client.PutAsJsonAsync($"/api/customers/{customer.Id}", new { name = "Edited online" });

        var result = await PushAsync(client, [
            Op("upd-stale", "customer", "update", customer.Id, stale,
                new { name = "Edited offline" })
        ]);

        Assert.Equal("conflict", result.Results[0].Status);
        Assert.Equal(1, result.Conflicts);
        Assert.NotNull(result.Results[0].Version);
    }

    [Fact]
    public async Task Push_UpdateWithCurrentBase_Applies()
    {
        var client = await CreateOwnerClientAsync();
        var customer = await CreateCustomerAsync(client, "Agreeable");
        var current = customer.UpdatedAt;

        var result = await PushAsync(client, [
            Op("upd-ok", "customer", "update", customer.Id, current,
                new { name = "Rewritten offline" })
        ]);

        Assert.Equal("applied", result.Results[0].Status);

        var fetched = await client.GetFromJsonAsync<CustomerDto>(
            $"/api/customers/{customer.Id}", JsonOptions);
        Assert.Equal("Rewritten offline", fetched!.Name);
    }

    [Fact]
    public async Task Push_DeleteOfMissingRecord_IsTreatedAsApplied()
    {
        var client = await CreateOwnerClientAsync();

        var result = await PushAsync(client, [
            Op("del-missing", "customer", "delete", 999999)
        ]);

        Assert.Equal("applied", result.Results[0].Status);
    }

    [Fact]
    public async Task Push_RejectsUnsupportedOperation()
    {
        var client = await CreateOwnerClientAsync();

        var result = await PushAsync(client, [
            Op("nope", "quotation", "delete", 1)
        ]);

        Assert.Equal("rejected", result.Results[0].Status);
        Assert.NotNull(result.Results[0].Error);
    }

    [Fact]
    public async Task Push_RejectsValidationFailures_WithoutLosingTheBatch()
    {
        var client = await CreateOwnerClientAsync();

        var result = await PushAsync(client, [
            Op("bad-1", "customer", "create", 0, payload: new { name = "" }),
            Op("good-1", "customer", "create", 0, payload: new { name = "Good One" })
        ]);

        Assert.Equal(2, result.Results.Count);
        Assert.Equal("rejected", result.Results[0].Status);
        Assert.Equal("applied", result.Results[1].Status);
        Assert.Equal(1, result.Applied);

        var list = await client.GetFromJsonAsync<PagedResult<CustomerDto>>(
            "/api/customers?pageSize=100", JsonOptions);
        Assert.Single(list!.Data);
    }

    [Fact]
    public async Task Push_CreatesSale_WithStockAndLedger()
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, 6000, 1000, 0, 10);
        var customer = await CreateCustomerAsync(client, "Offline Buyer");

        var result = await PushAsync(client, [
            Op("sale-1", "sale", "create", 0, payload: new
            {
                customerId = customer.Id,
                saleType = "Credit",
                items = new[] { new { productId = product.Id, quantity = 3, unitPrice = 1000 } },
                paidAmount = 0L,
            })
        ]);

        var single = Assert.Single(result.Results);
        Assert.Equal("applied", single.Status);

        // Stock moved and the khata was debited.
        var updated = await client.GetFromJsonAsync<ProductDto>(
            $"/api/products/{product.Id}", JsonOptions);
        Assert.Equal(7, updated!.StockQuantity);

        var ledger = await client.GetFromJsonAsync<PartyLedgerDto>(
            $"/api/customers/{customer.Id}/ledger", JsonOptions);
        Assert.Equal(3000, ledger!.Summary.ClosingBalance);
    }

    [Fact]
    public async Task Status_ReportsTheServerCursorAndLedger()
    {
        var client = await CreateOwnerClientAsync();

        var before = await client.GetFromJsonAsync<SyncStatusDto>("/api/sync/status", JsonOptions);
        Assert.Equal(0, before!.StoredOperations);

        await PushAsync(client, [Op("stat-1", "customer", "create", 0, payload: new { name = "Stat" })]);

        var after = await client.GetFromJsonAsync<SyncStatusDto>("/api/sync/status", JsonOptions);
        Assert.Equal(1, after!.StoredOperations);
        Assert.True(after.ServerTime >= before.ServerTime);
    }

    [Fact]
    public async Task OtherBusiness_SeesOnlyItsOwnChanges()
    {
        var ownerA = await CreateOwnerClientAsync();
        await CreateCustomerAsync(ownerA, "Business A Customer");

        var ownerB = await CreateOwnerClientAsync();
        await CreateCustomerAsync(ownerB, "Business B Customer");

        var pullB = await PullAsync(ownerB, since: null);
        var bCustomers = pullB.Changes.Where(c => c.EntityType == "customer").ToList();

        Assert.Contains("Business B Customer", bCustomers.Single().Payload!.ToString());
        Assert.DoesNotContain("Business A Customer", bCustomers.Single().Payload!.ToString());
    }

    // --- helpers ---

    private static object Op(
        string id, string entityType, string operation, long entityId,
        DateTime? baseUpdatedAt = null, object? payload = null)
        => new
        {
            operationId = id,
            entityType,
            operation,
            entityId,
            baseUpdatedAt,
            payload,
        };

    private static async Task<SyncPullResultDto> PullAsync(HttpClient client, DateTime? since)
    {
        var url = since is null ? "/api/sync/pull" : $"/api/sync/pull?since={since:O}";
        return (await client.GetFromJsonAsync<SyncPullResultDto>(url, JsonOptions))!;
    }

    private static async Task<SyncPushResultDto> PushAsync(
        HttpClient client, object[] operations)
    {
        var response = await client.PostAsJsonAsync("/api/sync/push", new { operations });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<SyncPushResultDto>(JsonOptions))!;
    }

    private static async Task<ProductDto> CreateProductAsync(
        HttpClient client, long costPrice, long sellingPrice, int taxRateBps, double openingQuantity)
    {
        var response = await client.PostAsJsonAsync("/api/products", new
        {
            name = $"P {Guid.NewGuid():n}",
            costPrice,
            sellingPrice,
            taxRateBps,
            openingQuantity,
        });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<ProductDto>(JsonOptions))!;
    }

    private static async Task<CustomerDto> CreateCustomerAsync(HttpClient client, string name)
    {
        var response = await client.PostAsJsonAsync("/api/customers", new { name });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<CustomerDto>(JsonOptions))!;
    }

    private static async Task<SupplierDto> CreateSupplierAsync(HttpClient client, string name)
    {
        var response = await client.PostAsJsonAsync("/api/suppliers", new { name });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<SupplierDto>(JsonOptions))!;
    }

    private static async Task<SaleDto> CreateSaleAsync(
        HttpClient client, long customerId, long productId, decimal quantity, long unitPrice)
    {
        var response = await client.PostAsJsonAsync("/api/sales", new
        {
            customerId,
            saleType = "Cash",
            items = new[] { new { productId, quantity, unitPrice } },
            paidAmount = unitPrice * (long)quantity,
        });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<SaleDto>(JsonOptions))!;
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
