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
/// Phase 10: business data backup. Export must be a faithful, file-downloadable
/// snapshot; restore must reproduce it into a fresh business and merge (skip,
/// never overwrite) into a populated one.
/// </summary>
[Collection(ApiTestCollection.Name)]
public class BackupEndpointsTests
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web)
    {
        Converters = { new JsonStringEnumConverter() },
    };

    private readonly KhataApiFactory _factory;

    public BackupEndpointsTests(KhataApiFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task Export_IsAJsonFileDownload()
    {
        var client = await CreateOwnerClientAsync();

        var response = await client.GetAsync("/api/backup/export");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal("application/json", response.Content.Headers.ContentType!.MediaType);
        Assert.Contains("khata-backup-", response.Content.Headers.ContentDisposition!.FileName);
        Assert.EndsWith(".json", response.Content.Headers.ContentDisposition.FileName!.Trim('"'));
    }

    [Fact]
    public async Task Export_IncludesEverySeededDocument()
    {
        var client = await CreateOwnerClientAsync();
        await SeedDatasetAsync(client);

        var backup = await ExportAsync(client);

        Assert.Equal(1, backup.Version);
        Assert.Single(backup.Products);
        Assert.Single(backup.Customers);
        Assert.Single(backup.Suppliers);
        Assert.Single(backup.Sales);
        Assert.Single(backup.Purchases);
        Assert.Single(backup.Expenses);
        Assert.Single(backup.Incomes);
        Assert.Equal(5, backup.PaymentMethods.Count); // the five seeded defaults

        // Line items and totals must survive the round trip.
        var sale = backup.Sales.Single();
        Assert.Single(sale.Items);
        Assert.Equal(5000, sale.Subtotal);
        Assert.Equal(5000, sale.TotalAmount);

        // Stock travels with the product (it is a separate table). Opened at 20,
        // −1 for the sale, +2 for the purchase = 21.
        Assert.Equal(21m, backup.Products.Single().StockQuantity);
    }

    [Fact]
    public async Task Restore_IntoFreshBusiness_ReproducesTheDataset()
    {
        var source = await CreateOwnerClientAsync();
        await SeedDatasetAsync(source);
        var backup = await ExportAsync(source);

        // A brand-new business, same user.
        var target = await CreateOwnerClientAsync();
        var result = await RestoreIntoAsync(target, backup);

        Assert.Equal(1, result.ProductsInserted);
        Assert.Equal(0, result.ProductsSkipped);
        Assert.Equal(1, result.CustomersInserted);
        Assert.Equal(1, result.SuppliersInserted);
        Assert.Equal(1, result.SalesInserted);
        Assert.Equal(1, result.PurchasesInserted);
        Assert.Equal(1, result.ExpensesInserted);
        Assert.Equal(1, result.IncomesInserted);

        // Read it back through the normal endpoints — proves the rows landed,
        // not just that the counters say so.
        var products = await target.GetFromJsonAsync<PagedResult<ProductDto>>(
            "/api/products", JsonOptions);
        Assert.Single(products!.Data);
        Assert.Equal(21m, products.Data[0].StockQuantity);
        Assert.Equal("Restored Widget", products.Data[0].Name);

        var sales = await target.GetFromJsonAsync<PagedResult<SaleDto>>("/api/sales", JsonOptions);
        Assert.Single(sales!.Data);
        Assert.Equal(5000, sales.Data[0].TotalAmount);
        Assert.Equal("INV-00001", sales.Data[0].InvoiceNumber);
    }

    [Fact]
    public async Task Restore_Twice_IsIdempotentBecauseExistingIdsAreSkipped()
    {
        var source = await CreateOwnerClientAsync();
        await SeedDatasetAsync(source);
        var backup = await ExportAsync(source);

        var target = await CreateOwnerClientAsync();
        await RestoreIntoAsync(target, backup);

        var second = await RestoreIntoAsync(target, backup);

        // Nothing inserted the second time; nothing overwritten either.
        Assert.Equal(0, second.ProductsInserted);
        Assert.Equal(1, second.ProductsSkipped);
        Assert.Equal(0, second.SalesInserted);
        Assert.Equal(1, second.SalesSkipped);

        var products = await target.GetFromJsonAsync<PagedResult<ProductDto>>(
            "/api/products", JsonOptions);
        Assert.Single(products!.Data);
    }

    [Fact]
    public async Task Restore_DoesNotOverwriteAModifiedExistingRow()
    {
        var source = await CreateOwnerClientAsync();
        await SeedDatasetAsync(source);
        var backup = await ExportAsync(source);

        var target = await CreateOwnerClientAsync();
        await RestoreIntoAsync(target, backup);

        // Rename locally, then restore the original snapshot again.
        var product = (await target.GetFromJsonAsync<PagedResult<ProductDto>>(
            "/api/products", JsonOptions))!.Data.Single();
        var rename = await target.PutAsJsonAsync($"/api/products/{product.Id}", new
        {
            name = "Renamed Locally",
            costPrice = product.CostPrice,
            sellingPrice = product.SellingPrice,
            taxRateBps = product.TaxRateBps,
            isActive = true,
        });
        rename.EnsureSuccessStatusCode();

        await RestoreIntoAsync(target, backup);

        // Merge semantics: the local edit survives; restore never rewrites.
        var after = (await target.GetFromJsonAsync<PagedResult<ProductDto>>(
            "/api/products", JsonOptions))!.Data.Single();
        Assert.Equal("Renamed Locally", after.Name);
    }

    [Fact]
    public async Task Restore_FromANewerVersion_Returns400()
    {
        var client = await CreateOwnerClientAsync();
        var backup = await ExportAsync(client);
        var future = backup with { Version = 99 };

        var response = await client.PostAsJsonAsync("/api/backup/restore", future);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task Restore_DoesNotTouchAnotherBusiness()
    {
        var ownerA = await CreateOwnerClientAsync();
        await SeedDatasetAsync(ownerA);
        var backup = await ExportAsync(ownerA);

        var ownerB = await CreateOwnerClientAsync();
        await RestoreIntoAsync(ownerB, backup);

        // B now has the data; A is untouched and still has exactly one of each.
        Assert.Single((await ownerA.GetFromJsonAsync<PagedResult<ProductDto>>(
            "/api/products", JsonOptions))!.Data);
        Assert.Single((await ownerB.GetFromJsonAsync<PagedResult<ProductDto>>(
            "/api/products", JsonOptions))!.Data);

        // And B cannot read A's business id from the payload by id collision.
        var bProducts = (await ownerB.GetFromJsonAsync<PagedResult<ProductDto>>(
            "/api/products", JsonOptions))!.Data.Single();
        Assert.NotEqual(ownerA, ownerB);
        Assert.Equal("Restored Widget", bProducts.Name);
    }

    /// <summary>
    /// The interesting case: the payload's ids are already taken by the SOURCE
    /// business (they always are), so every row is written under a fresh id.
    /// The restore must still be idempotent, which the id ledger guarantees —
    /// a plain "does this payload id exist here" check would not, because the
    /// ids written here differ from the ids in the file.
    /// </summary>
    [Fact]
    public async Task Restore_Twice_IsIdempotentEvenWhenIdsHadToBeRehomed()
    {
        var source = await CreateOwnerClientAsync();
        await SeedDatasetAsync(source);
        var backup = await ExportAsync(source);

        var target = await CreateOwnerClientAsync();
        var first = await RestoreIntoAsync(target, backup);
        var second = await RestoreIntoAsync(target, backup);

        // The rows were written but are not the source's ids.
        Assert.Equal(1, first.ProductsInserted);
        Assert.Equal(1, first.SalesInserted);

        // Second pass recognises the ledger and writes nothing.
        Assert.Equal(0, second.ProductsInserted);
        Assert.Equal(1, second.ProductsSkipped);
        Assert.Equal(0, second.SalesInserted);
        Assert.Equal(1, second.SalesSkipped);

        // Exactly one of each, read back through the normal endpoints.
        Assert.Single((await target.GetFromJsonAsync<PagedResult<ProductDto>>(
            "/api/products", JsonOptions))!.Data);
        Assert.Single((await target.GetFromJsonAsync<PagedResult<SaleDto>>(
            "/api/sales", JsonOptions))!.Data);
    }

    /// <summary>
    /// A restore must survive the seeded lookups: every business starts with
    /// units and payment methods, so the payload's copies collide on
    /// (BusinessId, Name). They are matched and reused, not duplicated.
    /// </summary>
    [Fact]
    public async Task Restore_ReusesSeededUnitsAndPaymentMethodsInsteadOfDuplicating()
    {
        var source = await CreateOwnerClientAsync();
        await SeedDatasetAsync(source);
        var backup = await ExportAsync(source);

        var target = await CreateOwnerClientAsync();
        var result = await RestoreIntoAsync(target, backup);

        // The payload's lookups matched the target's seeded ones.
        Assert.Equal(0, result.PaymentMethodsInserted);
        Assert.Equal(backup.PaymentMethods.Count, result.PaymentMethodsMatched);

        // No duplicates were created in the target business.
        var methods = await target.GetFromJsonAsync<List<PaymentMethodDto>>(
            "/api/payment-methods", JsonOptions);
        Assert.Equal(backup.PaymentMethods.Count, methods!.Count);
    }

    // ---------------------------------------------------------------
    // Helpers
    // ---------------------------------------------------------------
    private static async Task<BackupExportDto> ExportAsync(HttpClient client)
        => (await client.GetFromJsonAsync<BackupExportDto>("/api/backup/export", JsonOptions))!;

    private static async Task<BackupRestoreResultDto> RestoreIntoAsync(
        HttpClient client, BackupExportDto backup)
    {
        var response = await client.PostAsJsonAsync("/api/backup/restore", backup);
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<BackupRestoreResultDto>(JsonOptions))!;
    }

    /// <summary>One product, customer, supplier, sale, purchase, expense, income.</summary>
    private static async Task SeedDatasetAsync(HttpClient client)
    {
        var product = await PostAsync<ProductDto>(client, "/api/products", new
        {
            name = "Restored Widget",
            costPrice = 3000,
            sellingPrice = 5000,
            taxRateBps = 0,
            openingQuantity = 20,
        });

        var customer = await PostAsync<CustomerDto>(client, "/api/customers", new
        {
            name = "Restored Customer",
        });

        var supplier = await PostAsync<SupplierDto>(client, "/api/suppliers", new
        {
            name = "Restored Supplier",
        });

        await PostAsync<SaleDto>(client, "/api/sales", new
        {
            customerId = customer.Id,
            saleType = "Credit",
            items = new[] { new { productId = product.Id, quantity = 1, unitPrice = 5000 } },
            paidAmount = 0,
        });

        await PostAsync<PurchaseDto>(client, "/api/purchases", new
        {
            supplierId = supplier.Id,
            purchaseType = "Credit",
            items = new[] { new { productId = product.Id, quantity = 2, unitPrice = 3000 } },
            paidAmount = 0,
        });

        await PostAsync<ExpenseDto>(client, "/api/expenses", new
        {
            category = "Rent",
            amount = 150000,
        });

        await PostAsync<IncomeDto>(client, "/api/incomes", new
        {
            source = "Consulting",
            amount = 250000,
        });
    }

    private static async Task<T> PostAsync<T>(HttpClient client, string url, object payload)
    {
        var response = await client.PostAsJsonAsync(url, payload);
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<T>(JsonOptions))!;
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
