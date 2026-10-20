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
/// Product catalog: categories, units, products CRUD, search, conflicts and
/// cross-business tenant isolation.
/// </summary>
[Collection(ApiTestCollection.Name)]
public class ProductEndpointsTests
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web)
    {
        Converters = { new JsonStringEnumConverter() },
    };
    private readonly KhataApiFactory _factory;

    public ProductEndpointsTests(KhataApiFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task NewBusiness_SeedsDefaultUnitsAndGeneralCategory()
    {
        var client = await CreateOwnerClientAsync();

        var units = await client.GetFromJsonAsync<List<UnitDto>>("/api/units", JsonOptions);
        Assert.Contains(units!, u => u.Name == "Piece" && u.ShortName == "pc");
        Assert.Contains(units!, u => u.Name == "Kilogram");

        var categories = await client.GetFromJsonAsync<List<CategoryDto>>("/api/categories", JsonOptions);
        Assert.Contains(categories!, c => c.Name == "General");
    }

    [Fact]
    public async Task CreateProduct_WithOpeningStock_RecordsOpeningMovement()
    {
        var client = await CreateOwnerClientAsync();

        var product = await CreateProductAsync(client, $"Noodles {Guid.NewGuid():n}", openingQuantity: 25, minQuantity: 5);

        Assert.Equal(25m, product.StockQuantity);
        Assert.Equal(5m, product.MinQuantity);
        Assert.False(product.IsLowStock);

        var movements = await client.GetFromJsonAsync<PagedResult<StockMovementDto>>(
            $"/api/inventory/{product.Id}/movements", JsonOptions);
        var movement = Assert.Single(movements!.Data);
        Assert.Equal(Domain.Enums.StockMovementType.Opening, movement.MovementType);
        Assert.Equal(25m, movement.BalanceAfter);
    }

    [Fact]
    public async Task GetProducts_SupportsSearchByNameSkuAndBarcode()
    {
        var client = await CreateOwnerClientAsync();
        var suffix = Guid.NewGuid().ToString("n")[..8];

        await CreateProductAsync(client, $"Coca Cola {suffix}", sku: $"SKU-{suffix}");
        await CreateProductAsync(client, $"Sprite {suffix}", barcode: $"BAR-{suffix}");

        var byName = await GetProductsAsync(client, search: $"Cola {suffix}");
        Assert.Single(byName);
        Assert.Contains("Coca", byName[0].Name);

        var bySku = await GetProductsAsync(client, search: $"SKU-{suffix}");
        Assert.Single(bySku);

        var byBarcode = await GetProductsAsync(client, search: $"BAR-{suffix}");
        Assert.Single(byBarcode);
    }

    [Fact]
    public async Task UpdateProduct_ChangesPrices_ButNotStockQuantity()
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, $"Sugar {Guid.NewGuid():n}",
            costPrice: 8000, sellingPrice: 9500, openingQuantity: 10, minQuantity: 2);

        var update = await client.PutAsJsonAsync($"/api/products/{product.Id}", new
        {
            name = product.Name,
            costPrice = 8200L,
            sellingPrice = 9900L,
            taxRateBps = 0,
            minQuantity = 4,
        });
        update.EnsureSuccessStatusCode();
        var updated = await update.Content.ReadFromJsonAsync<ProductDto>(JsonOptions);

        Assert.Equal(8200, updated!.CostPrice);
        Assert.Equal(9900, updated.SellingPrice);
        Assert.Equal(4, updated.MinQuantity);
        Assert.Equal(10, updated.StockQuantity); // untouched by product edit
    }

    [Fact]
    public async Task CreateProduct_WithDuplicateSku_Returns409()
    {
        var client = await CreateOwnerClientAsync();
        var sku = $"DUP-{Guid.NewGuid():n}";
        await CreateProductAsync(client, $"First {Guid.NewGuid():n}", sku: sku);

        var second = await client.PostAsJsonAsync("/api/products", new { name = "Second", sku });
        Assert.Equal(HttpStatusCode.Conflict, second.StatusCode);
    }

    [Fact]
    public async Task CreateProduct_WithDuplicateBarcode_Returns409()
    {
        var client = await CreateOwnerClientAsync();
        var barcode = $"BC-{Guid.NewGuid():n}";
        await CreateProductAsync(client, $"First {Guid.NewGuid():n}", barcode: barcode);

        var second = await client.PostAsJsonAsync("/api/products", new { name = "Second", barcode });
        Assert.Equal(HttpStatusCode.Conflict, second.StatusCode);
    }

    [Fact]
    public async Task CreateProduct_WithUnknownCategory_Returns404()
    {
        var client = await CreateOwnerClientAsync();

        var response = await client.PostAsJsonAsync("/api/products", new
        {
            name = $"Orphan {Guid.NewGuid():n}",
            categoryId = 999_999L,
        });

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task CreateProduct_WithEmptyName_Returns400()
    {
        var client = await CreateOwnerClientAsync();

        var response = await client.PostAsJsonAsync("/api/products", new { name = "" });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task DeleteProduct_HidesItFromList_AndGetReturns404()
    {
        var client = await CreateOwnerClientAsync();
        var product = await CreateProductAsync(client, $"Discontinued {Guid.NewGuid():n}", openingQuantity: 3);

        var delete = await client.DeleteAsync($"/api/products/{product.Id}");
        Assert.Equal(HttpStatusCode.NoContent, delete.StatusCode);

        var get = await client.GetAsync($"/api/products/{product.Id}");
        Assert.Equal(HttpStatusCode.NotFound, get.StatusCode);

        var list = await GetProductsAsync(client);
        Assert.DoesNotContain(list, p => p.Id == product.Id);
    }

    [Fact]
    public async Task CategoryDelete_MovesProductsToNoCategory()
    {
        var client = await CreateOwnerClientAsync();
        var category = await CreateCategoryAsync(client, $"Seasonal {Guid.NewGuid():n}");
        var product = await CreateProductAsync(client, $"Tea {Guid.NewGuid():n}", categoryId: category.Id);
        Assert.Equal(category.Id, product.CategoryId);

        var delete = await client.DeleteAsync($"/api/categories/{category.Id}");
        Assert.Equal(HttpStatusCode.NoContent, delete.StatusCode);

        var fetched = await client.GetFromJsonAsync<ProductDto>($"/api/products/{product.Id}", JsonOptions);
        Assert.Null(fetched!.CategoryId);
        Assert.Null(fetched.CategoryName);
    }

    [Fact]
    public async Task CategoryDelete_WithActiveChildren_Returns422()
    {
        var client = await CreateOwnerClientAsync();
        var parent = await CreateCategoryAsync(client, $"Drinks {Guid.NewGuid():n}");
        await client.PostAsJsonAsync("/api/categories", new
        {
            name = $"Water {Guid.NewGuid():n}",
            parentId = parent.Id,
        });

        var delete = await client.DeleteAsync($"/api/categories/{parent.Id}");
        Assert.Equal(HttpStatusCode.UnprocessableEntity, delete.StatusCode);
    }

    [Fact]
    public async Task UnitDelete_MovesProductsToNoUnit()
    {
        var client = await CreateOwnerClientAsync();
        var unit = await CreateUnitAsync(client, "Sack", "sack");
        var product = await CreateProductAsync(client, $"Rice {Guid.NewGuid():n}", unitId: unit.Id);
        Assert.Equal(unit.Id, product.UnitId);

        var delete = await client.DeleteAsync($"/api/units/{unit.Id}");
        Assert.Equal(HttpStatusCode.NoContent, delete.StatusCode);

        var fetched = await client.GetFromJsonAsync<ProductDto>($"/api/products/{product.Id}", JsonOptions);
        Assert.Null(fetched!.UnitId);
    }

    [Fact]
    public async Task CreateUnit_WithDuplicateName_Returns409()
    {
        var client = await CreateOwnerClientAsync();

        var first = await client.PostAsJsonAsync("/api/units", new { name = "Bundle", shortName = "bdl" });
        first.EnsureSuccessStatusCode();
        var second = await client.PostAsJsonAsync("/api/units", new { name = "bundle", shortName = "bdl" });

        Assert.Equal(HttpStatusCode.Conflict, second.StatusCode);
    }

    [Fact]
    public async Task OtherBusiness_CannotSeeOrTouchProducts_Returns404()
    {
        // Business A with a product.
        var ownerA = await CreateOwnerClientAsync();
        var productA = await CreateProductAsync(ownerA, $"Private Stock {Guid.NewGuid():n}", openingQuantity: 5);

        // Business B (a different user with its own business).
        var ownerB = await CreateOwnerClientAsync();
        await CreateProductAsync(ownerB, $"Their Stock {Guid.NewGuid():n}", openingQuantity: 7);

        // Cross-tenant access is invisible (404, not 403) — existence isn't leaked.
        var get = await ownerB.GetAsync($"/api/products/{productA.Id}");
        Assert.Equal(HttpStatusCode.NotFound, get.StatusCode);

        var update = await ownerB.PutAsJsonAsync($"/api/products/{productA.Id}", new { name = "hijacked" });
        Assert.Equal(HttpStatusCode.NotFound, update.StatusCode);

        var adjust = await ownerB.PostAsJsonAsync($"/api/inventory/{productA.Id}/adjust",
            new { quantity = 100m });
        Assert.Equal(HttpStatusCode.NotFound, adjust.StatusCode);

        // B's list holds only B's product.
        var list = await GetProductsAsync(ownerB);
        Assert.DoesNotContain(list, p => p.Id == productA.Id);
    }

    // --- helpers ---

    private static async Task<List<ProductDto>> GetProductsAsync(HttpClient client, string? search = null)
    {
        var url = string.IsNullOrEmpty(search) ? "/api/products" : $"/api/products?search={Uri.EscapeDataString(search)}";
        var page = await client.GetFromJsonAsync<PagedResult<ProductDto>>(url, JsonOptions);
        return page!.Data.ToList();
    }

    private static async Task<ProductDto> CreateProductAsync(
        HttpClient client,
        string name,
        string? sku = null,
        string? barcode = null,
        long? categoryId = null,
        long? unitId = null,
        long costPrice = 1500,
        long sellingPrice = 2000,
        decimal openingQuantity = 0,
        decimal minQuantity = 0)
    {
        var response = await client.PostAsJsonAsync("/api/products", new
        {
            name,
            sku,
            barcode,
            categoryId,
            unitId,
            costPrice,
            sellingPrice,
            taxRateBps = 0,
            openingQuantity,
            minQuantity,
        });
        response.EnsureSuccessStatusCode();
        var product = await response.Content.ReadFromJsonAsync<ProductDto>(JsonOptions);
        Assert.NotNull(product);
        return product!;
    }

    private static async Task<CategoryDto> CreateCategoryAsync(HttpClient client, string name)
    {
        var response = await client.PostAsJsonAsync("/api/categories", new { name });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<CategoryDto>(JsonOptions))!;
    }

    private static async Task<UnitDto> CreateUnitAsync(HttpClient client, string name, string shortName)
    {
        var response = await client.PostAsJsonAsync("/api/units", new { name, shortName });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<UnitDto>(JsonOptions))!;
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
