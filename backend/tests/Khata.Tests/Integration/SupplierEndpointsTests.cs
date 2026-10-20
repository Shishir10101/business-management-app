using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Domain.Enums;
using Khata.Tests.Testing;
using Xunit;

namespace Khata.Tests.Integration;

/// <summary>
/// Suppliers + supplier khata ledger. Balance direction is the mirror of
/// customers: opening +, purchases, we-owe grow the balance as CREDITS.
/// </summary>
[Collection(ApiTestCollection.Name)]
public class SupplierEndpointsTests
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web)
    {
        Converters = { new JsonStringEnumConverter() },
    };
    private readonly KhataApiFactory _factory;

    public SupplierEndpointsTests(KhataApiFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task CreateSupplier_WithOpeningBalance_CreatesLedgerWithCreditTxn()
    {
        var client = await CreateOwnerClientAsync();

        var supplier = await CreateSupplierAsync(client, $"Wholesale {Guid.NewGuid():n}",
            openingBalance: 200000);

        Assert.Equal(200000, supplier.CurrentBalance);

        var ledger = await GetLedgerAsync(client, supplier.Id);
        var txn = Assert.Single(ledger.Data);

        // Supplier: we owe → opening balance is a CREDIT.
        Assert.Equal(LedgerEntryType.Credit, txn.TransactionType);
        Assert.Equal(200000, txn.Amount);
        Assert.Equal(200000, txn.BalanceAfter);

        Assert.Equal(200000, ledger.Summary.OpeningBalance);
        Assert.Equal(0, ledger.Summary.TotalDebit);
        Assert.Equal(200000, ledger.Summary.TotalCredit);
        Assert.Equal(200000, ledger.Summary.ClosingBalance);
    }

    [Fact]
    public async Task UpdateSupplier_OpeningBalanceIncrease_AppendsCreditAdjustment()
    {
        var client = await CreateOwnerClientAsync();
        var supplier = await CreateSupplierAsync(client, $"Distributor {Guid.NewGuid():n}",
            openingBalance: 100000);

        await UpdateOpeningAsync(client, supplier.Id, supplier.Name, 160000);

        var ledger = await GetLedgerAsync(client, supplier.Id);
        Assert.Equal(2, ledger.Data.Count);

        var newest = ledger.Data[0];
        Assert.Equal("adjustment", newest.ReferenceType);
        Assert.Equal(LedgerEntryType.Credit, newest.TransactionType);
        Assert.Equal(60000, newest.Amount);
        Assert.Equal(160000, newest.BalanceAfter);

        Assert.Equal(160000, ledger.Summary.ClosingBalance);
        Assert.Equal(160000, ledger.Summary.TotalCredit); // 100000 opening + 60000 adjustment
    }

    [Fact]
    public async Task UpdateSupplier_OpeningBalanceDecrease_AppendsDebitAdjustment()
    {
        var client = await CreateOwnerClientAsync();
        var supplier = await CreateSupplierAsync(client, $"Partial {Guid.NewGuid():n}",
            openingBalance: 100000);

        await UpdateOpeningAsync(client, supplier.Id, supplier.Name, 40000);

        var ledger = await GetLedgerAsync(client, supplier.Id);
        var newest = ledger.Data[0];
        Assert.Equal(LedgerEntryType.Debit, newest.TransactionType);
        Assert.Equal(60000, newest.Amount);
        Assert.Equal(40000, newest.BalanceAfter);

        Assert.Equal(40000, ledger.Summary.ClosingBalance);
    }

    [Fact]
    public async Task SupplierLedgerBalanceCalculation_IsCorrectAcrossAdjustments()
    {
        var client = await CreateOwnerClientAsync();
        // Opening 50000 → +30000 → -20000 = closing 60000.
        var supplier = await CreateSupplierAsync(client, $"Calc {Guid.NewGuid():n}",
            openingBalance: 50000);
        await UpdateOpeningAsync(client, supplier.Id, supplier.Name, 80000);
        await UpdateOpeningAsync(client, supplier.Id, supplier.Name, 60000);

        var ledger = await GetLedgerAsync(client, supplier.Id);
        Assert.Equal(3, ledger.Data.Count);

        Assert.Equal(60000, ledger.Data[0].BalanceAfter);
        Assert.Equal(80000, ledger.Data[1].BalanceAfter);
        Assert.Equal(50000, ledger.Data[2].BalanceAfter);

        Assert.Equal(50000, ledger.Summary.OpeningBalance);
        Assert.Equal(80000, ledger.Summary.TotalCredit); // 50000 opening + 30000 adjustment
        Assert.Equal(20000, ledger.Summary.TotalDebit);  // -20000 adjustment
        Assert.Equal(60000, ledger.Summary.ClosingBalance);
    }

    [Fact]
    public async Task GetSuppliers_SupportsSearch()
    {
        var client = await CreateOwnerClientAsync();
        var suffix = Guid.NewGuid().ToString("n")[..8];
        await CreateSupplierAsync(client, $"Noodles Co {suffix}");
        await CreateSupplierAsync(client, $"Rice Mill {suffix}");

        var found = await GetSuppliersAsync(client, search: $"rice mill {suffix}");
        Assert.Single(found);
        Assert.Contains("Rice", found[0].Name);
    }

    [Fact]
    public async Task OtherBusiness_CannotSeeSupplier_Returns404()
    {
        var ownerA = await CreateOwnerClientAsync();
        var supplierA = await CreateSupplierAsync(ownerA, $"Secret Vendor {Guid.NewGuid():n}",
            openingBalance: 50000);

        var ownerB = await CreateOwnerClientAsync();

        var get = await ownerB.GetAsync($"/api/suppliers/{supplierA.Id}");
        Assert.Equal(HttpStatusCode.NotFound, get.StatusCode);

        var list = await GetSuppliersAsync(ownerB);
        Assert.DoesNotContain(list, s => s.Id == supplierA.Id);
    }

    [Fact]
    public async Task CreateSupplier_WithEmptyName_Returns400()
    {
        var client = await CreateOwnerClientAsync();

        var response = await client.PostAsJsonAsync("/api/suppliers", new { name = "" });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    // --- helpers ---

    private static async Task<SupplierDto> CreateSupplierAsync(
        HttpClient client, string name, long openingBalance = 0)
    {
        var response = await client.PostAsJsonAsync("/api/suppliers", new
        {
            name,
            openingBalance,
        });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<SupplierDto>(JsonOptions))!;
    }

    private static async Task UpdateOpeningAsync(
        HttpClient client, long id, string name, long openingBalance)
    {
        var response = await client.PutAsJsonAsync($"/api/suppliers/{id}", new
        {
            name,
            openingBalance,
        });
        response.EnsureSuccessStatusCode();
    }

    private static async Task<List<SupplierDto>> GetSuppliersAsync(HttpClient client, string? search = null)
    {
        var url = string.IsNullOrEmpty(search)
            ? "/api/suppliers?pageSize=100"
            : $"/api/suppliers?search={Uri.EscapeDataString(search)}&pageSize=100";
        var page = await client.GetFromJsonAsync<PagedResult<SupplierDto>>(url, JsonOptions);
        return page!.Data.ToList();
    }

    private static async Task<PartyLedgerDto> GetLedgerAsync(HttpClient client, long supplierId)
    {
        var ledger = await client.GetFromJsonAsync<PartyLedgerDto>(
            $"/api/suppliers/{supplierId}/ledger?pageSize=100", JsonOptions);
        return ledger!;
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
