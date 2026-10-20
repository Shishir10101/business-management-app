using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Domain.Enums;
using Khata.Infrastructure.Data;
using Khata.Tests.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Khata.Tests.Integration;

/// <summary>
/// Inventory: stock adjustments, the immutable movement ledger, running balance
/// correctness, and low-stock queries.
/// </summary>
[Collection(ApiTestCollection.Name)]
public class InventoryEndpointsTests
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web)
    {
        Converters = { new JsonStringEnumConverter() },
    };
    private readonly KhataApiFactory _factory;

    public InventoryEndpointsTests(KhataApiFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task AdjustStock_InAndOut_UpdatesQuantityAndAppendsMovements()
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, $"Adjustable {Guid.NewGuid():n}",
            openingQuantity: 25, minQuantity: 5);

        var inResponse = await AdjustAsync(client, product.Id, 5, "delivery");
        inResponse.EnsureSuccessStatusCode();
        var inResult = await inResponse.Content.ReadFromJsonAsync<AdjustStockResponse>(JsonOptions);
        Assert.Equal(30m, inResult!.Quantity);
        Assert.Equal(StockMovementType.AdjustmentIn, inResult.Movement.MovementType);
        Assert.Equal(30m, inResult.Movement.BalanceAfter);

        var outResponse = await AdjustAsync(client, product.Id, -8, "sold");
        outResponse.EnsureSuccessStatusCode();
        var outResult = await outResponse.Content.ReadFromJsonAsync<AdjustStockResponse>(JsonOptions);
        Assert.Equal(StockMovementType.AdjustmentOut, outResult!.Movement.MovementType);
        Assert.Equal(22m, outResult.Movement.BalanceAfter);

        // Newest first: sold (-8, 22) then delivery (+5, 30) then opening (25).
        var movements = await GetMovementsAsync(client, product.Id);
        Assert.Equal(3, movements.Count);
        Assert.Equal(-8m, movements[0].Quantity);
        Assert.Equal(22m, movements[0].BalanceAfter);
        Assert.Equal(5m, movements[1].Quantity);
        Assert.Equal(30m, movements[1].BalanceAfter);
        Assert.Equal(25m, movements[2].Quantity);
        Assert.Equal(25m, movements[2].BalanceAfter);
        Assert.Equal(StockMovementType.Opening, movements[2].MovementType);
    }

    [Fact]
    public async Task AdjustStock_BelowZero_Returns422_AndKeepsStock()
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, $"Scarce {Guid.NewGuid():n}", openingQuantity: 5);

        var response = await AdjustAsync(client, product.Id, -10, "oversell attempt");

        Assert.Equal(HttpStatusCode.UnprocessableEntity, response.StatusCode);

        var fetched = await client.GetFromJsonAsync<ProductDto>($"/api/products/{product.Id}", JsonOptions);
        Assert.Equal(5m, fetched!.StockQuantity);

        // No movement was recorded for the rejected adjustment.
        var movements = await GetMovementsAsync(client, product.Id);
        Assert.Single(movements); // only the opening movement
    }

    [Fact]
    public async Task AdjustStock_WithZero_Returns400()
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, $"NoOp {Guid.NewGuid():n}");

        var response = await AdjustAsync(client, product.Id, 0);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task AdjustStock_ForUnknownProduct_Returns404()
    {
        var client = await CreateOwnerClientAsync();

        var response = await AdjustAsync(client, 999_999, 5);

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task Movements_ForUnknownProduct_Returns404()
    {
        var client = await CreateOwnerClientAsync();

        var response = await client.GetAsync($"/api/inventory/999_999/movements");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task StockCalculation_MovementsSumEqualsCurrentQuantity()
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, $"Running {Guid.NewGuid():n}", openingQuantity: 100);

        // +40, -15, -25, +10 => 110
        await AdjustAsync(client, product.Id, 40);
        await AdjustAsync(client, product.Id, -15);
        await AdjustAsync(client, product.Id, -25);
        await AdjustAsync(client, product.Id, 10);

        var movements = await GetMovementsAsync(client, product.Id);
        var sum = movements.Sum(m => m.Quantity);

        Assert.Equal(110m, sum);
        Assert.Equal(sum, movements[0].BalanceAfter); // newest balance == running sum
        Assert.Equal(product.Id, movements[0].ProductId);
    }

    [Fact]
    public async Task LowStock_FiltersProductsAtOrBelowMinimum()
    {
        var client = await CreateOwnerClientAsync();

        var low = await CreateProductAsync(client, $"Low Milk {Guid.NewGuid():n}",
            openingQuantity: 3, minQuantity: 5);
        var healthy = await CreateProductAsync(client, $"Fine Flour {Guid.NewGuid():n}",
            openingQuantity: 50, minQuantity: 5);
        var noThreshold = await CreateProductAsync(client, $"No Threshold {Guid.NewGuid():n}",
            openingQuantity: 0, minQuantity: 0);

        Assert.True(low.IsLowStock);
        Assert.False(healthy.IsLowStock);
        Assert.False(noThreshold.IsLowStock); // min = 0 means "no threshold"

        var alerts = await client.GetFromJsonAsync<List<ProductDto>>("/api/inventory/low-stock", JsonOptions);
        Assert.Contains(alerts!, p => p.Id == low.Id);
        Assert.DoesNotContain(alerts!, p => p.Id == healthy.Id);
        Assert.DoesNotContain(alerts!, p => p.Id == noThreshold.Id);

        // The inventory list supports the same filter.
        var filtered = await client.GetFromJsonAsync<PagedResult<ProductDto>>(
            "/api/inventory?lowStockOnly=true", JsonOptions);
        Assert.Contains(filtered!.Data, p => p.Id == low.Id);
        Assert.DoesNotContain(filtered.Data, p => p.Id == healthy.Id);
    }

    [Fact]
    public async Task InventoryList_CanSortByQuantity()
    {
        var client = await CreateOwnerClientAsync();
        var high = await CreateProductAsync(client, $"High {Guid.NewGuid():n}", openingQuantity: 90);
        var mid = await CreateProductAsync(client, $"Mid {Guid.NewGuid():n}", openingQuantity: 40);
        var zero = await CreateProductAsync(client, $"Zero {Guid.NewGuid():n}", openingQuantity: 0);

        var page = await client.GetFromJsonAsync<PagedResult<ProductDto>>(
            "/api/inventory?sortBy=quantity&pageSize=100", JsonOptions);

        var ordered = page!.Data.Where(p => new[] { high.Id, mid.Id, zero.Id }.Contains(p.Id))
            .OrderBy(p => p.Id).ToList();
        Assert.Equal(3, ordered.Count);

        var all = page.Data.ToList();
        var indexOf = (long id) => all.FindIndex(p => p.Id == id);
        Assert.True(indexOf(zero.Id) < indexOf(mid.Id));
        Assert.True(indexOf(mid.Id) < indexOf(high.Id));
    }

    [Fact]
    public async Task StockMovements_AreImmutable_UpdateAndDeleteAreRejected()
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, $"Ledger {Guid.NewGuid():n}", openingQuantity: 10);
        await AdjustAsync(client, product.Id, 5);

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<KhataDbContext>();

        var movement = await db.StockMovements.IgnoreQueryFilters()
            .FirstAsync(m => m.ProductId == product.Id && m.MovementType == StockMovementType.AdjustmentIn);

        movement.Notes = "rewritten history";
        var updateError = await Assert.ThrowsAsync<InvalidOperationException>(
            () => db.SaveChangesAsync());
        Assert.Contains("immutable", updateError.Message);

        // Reset the tracked change, then attempt a hard delete.
        movement.Notes = null;
        db.Entry(movement).State = EntityState.Unchanged;

        db.StockMovements.Remove(movement);
        var deleteError = await Assert.ThrowsAsync<InvalidOperationException>(
            () => db.SaveChangesAsync());
        Assert.Contains("immutable", deleteError.Message);

        // The stored movement is unchanged.
        db.Entry(movement).State = EntityState.Detached;
        var stored = await db.StockMovements.IgnoreQueryFilters()
            .AsNoTracking()
            .FirstAsync(m => m.Id == movement.Id);
        Assert.Null(stored.Notes);
    }

    // --- helpers ---

    private static async Task<HttpResponseMessage> AdjustAsync(HttpClient client, long productId, decimal quantity, string? notes = null)
        => await client.PostAsJsonAsync($"/api/inventory/{productId}/adjust", new { quantity, notes });

    private static async Task<List<StockMovementDto>> GetMovementsAsync(HttpClient client, long productId)
    {
        var page = await client.GetFromJsonAsync<PagedResult<StockMovementDto>>(
            $"/api/inventory/{productId}/movements?pageSize=100", JsonOptions);
        return page!.Data.ToList();
    }

    private static async Task<ProductDto> CreateProductAsync(
        HttpClient client, string name, decimal openingQuantity = 0, decimal minQuantity = 0)
    {
        var response = await client.PostAsJsonAsync("/api/products", new
        {
            name,
            costPrice = 1500,
            sellingPrice = 2000,
            taxRateBps = 0,
            openingQuantity,
            minQuantity,
        });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<ProductDto>(JsonOptions))!;
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
