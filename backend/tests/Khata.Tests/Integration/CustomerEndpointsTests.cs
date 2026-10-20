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
/// Customers + customer khata ledger: opening balance → ledger account +
/// opening transaction, adjustments, summary/balance correctness,
/// immutability, and cross-business isolation.
/// </summary>
[Collection(ApiTestCollection.Name)]
public class CustomerEndpointsTests
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web)
    {
        Converters = { new JsonStringEnumConverter() },
    };
    private readonly KhataApiFactory _factory;

    public CustomerEndpointsTests(KhataApiFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task CreateCustomer_WithOpeningBalance_CreatesLedgerAccountAndOpeningTxn()
    {
        var client = await CreateOwnerClientAsync();

        var customer = await CreateCustomerAsync(client, $"Hari {Guid.NewGuid():n}",
            openingBalance: 100000);

        Assert.Equal(100000, customer.OpeningBalance);
        Assert.Equal(100000, customer.CurrentBalance);

        var ledger = await GetLedgerAsync(client, customer.Id);
        var summary = Assert.Single(ledger.Data);
        Assert.Equal(LedgerEntryType.Debit, summary.TransactionType);
        Assert.Equal(100000, summary.Amount);
        Assert.Equal(100000, summary.BalanceAfter);
        Assert.Equal("opening", summary.ReferenceType);
    }

    [Fact]
    public async Task CreateCustomer_WithNegativeOpeningBalance_RecordsCreditTxn()
    {
        var client = await CreateOwnerClientAsync();

        // Customer paid an advance: negative receivable.
        var customer = await CreateCustomerAsync(client, $"Advance {Guid.NewGuid():n}",
            openingBalance: -50000);

        Assert.Equal(-50000, customer.CurrentBalance);

        var ledger = await GetLedgerAsync(client, customer.Id);
        var txn = Assert.Single(ledger.Data);
        Assert.Equal(LedgerEntryType.Credit, txn.TransactionType);
        Assert.Equal(50000, txn.Amount);
        Assert.Equal(-50000, txn.BalanceAfter);
    }

    [Fact]
    public async Task CreateCustomer_WithZeroOpeningBalance_HasEmptyLedger()
    {
        var client = await CreateOwnerClientAsync();

        var customer = await CreateCustomerAsync(client, $"Fresh {Guid.NewGuid():n}");

        Assert.Equal(0, customer.CurrentBalance);

        var ledger = await GetLedgerAsync(client, customer.Id);
        Assert.Empty(ledger.Data);
        Assert.Equal(0, ledger.Summary.ClosingBalance);
    }

    [Fact]
    public async Task CreateCustomer_WithEmptyName_Returns400()
    {
        var client = await CreateOwnerClientAsync();

        var response = await client.PostAsJsonAsync("/api/customers", new { name = "" });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task GetCustomers_SupportsSearchByNameAndPhone()
    {
        var client = await CreateOwnerClientAsync();
        var suffix = Guid.NewGuid().ToString("n")[..8];
        await CreateCustomerAsync(client, $"Ram {suffix}", phoneNumber: "9811234567");
        await CreateCustomerAsync(client, $"Shyam {suffix}", phoneNumber: "9807654321");

        var byName = await GetCustomersAsync(client, search: $"ram {suffix}");
        Assert.Single(byName);
        Assert.Contains("Ram", byName[0].Name);

        var byPhone = await GetCustomersAsync(client, search: "9807654321");
        Assert.Single(byPhone);
        Assert.Contains("Shyam", byPhone[0].Name);
    }

    [Fact]
    public async Task UpdateCustomer_OpeningBalanceChange_AppendsAdjustment_KeepsOpeningTxn()
    {
        var client = await CreateOwnerClientAsync();
        var customer = await CreateCustomerAsync(client, $"Ledger {Guid.NewGuid():n}",
            openingBalance: 100000);

        var update = await client.PutAsJsonAsync($"/api/customers/{customer.Id}", new
        {
            name = customer.Name,
            openingBalance = 150000L,
        });
        update.EnsureSuccessStatusCode();
        var updated = await update.Content.ReadFromJsonAsync<CustomerDto>(JsonOptions);
        Assert.Equal(150000, updated!.CurrentBalance);

        // Ledger: opening txn (1000) + adjustment (+500). Original untouched.
        var ledger = await GetLedgerAsync(client, customer.Id);
        Assert.Equal(2, ledger.Data.Count);

        var newest = ledger.Data[0];
        Assert.Equal("adjustment", newest.ReferenceType);
        Assert.Equal(LedgerEntryType.Debit, newest.TransactionType);
        Assert.Equal(50000, newest.Amount);
        Assert.Equal(150000, newest.BalanceAfter);

        var opening = ledger.Data[1];
        Assert.Equal("opening", opening.ReferenceType);
        Assert.Equal(100000, opening.Amount);
        Assert.Equal(100000, opening.BalanceAfter);

        Assert.Equal(100000, ledger.Summary.OpeningBalance);
        Assert.Equal(150000, ledger.Summary.TotalDebit);
        Assert.Equal(0, ledger.Summary.TotalCredit);
        Assert.Equal(150000, ledger.Summary.ClosingBalance);
    }

    [Fact]
    public async Task LedgerBalanceCalculation_IsCorrectAcrossMixedTransactions()
    {
        var client = await CreateOwnerClientAsync();
        // Opening 1000 → +500 → -250 = closing 1250.
        var customer = await CreateCustomerAsync(client, $"Running {Guid.NewGuid():n}",
            openingBalance: 100000);
        await UpdateOpeningAsync(client, "/api/customers", customer.Id, customer.Name, 150000);
        await UpdateOpeningAsync(client, "/api/customers", customer.Id, customer.Name, 125000);

        var ledger = await GetLedgerAsync(client, customer.Id);
        Assert.Equal(3, ledger.Data.Count);

        // Newest first; each balance_after must equal the running natural balance.
        Assert.Equal(125000, ledger.Data[0].BalanceAfter);
        Assert.Equal(150000, ledger.Data[1].BalanceAfter);
        Assert.Equal(100000, ledger.Data[2].BalanceAfter);

        // Closing == sum of all signed deltas on top of opening.
        Assert.Equal(100000, ledger.Summary.OpeningBalance);
        Assert.Equal(150000, ledger.Summary.TotalDebit); // 100000 + 50000
        Assert.Equal(25000, ledger.Summary.TotalCredit); // -25000
        Assert.Equal(125000, ledger.Summary.ClosingBalance);
    }

    [Fact]
    public async Task DeleteCustomer_HidesItFromList_AndGetReturns404()
    {
        var client = await CreateOwnerClientAsync();
        var customer = await CreateCustomerAsync(client, $"Leaver {Guid.NewGuid():n}",
            openingBalance: 5000);

        var delete = await client.DeleteAsync($"/api/customers/{customer.Id}");
        Assert.Equal(HttpStatusCode.NoContent, delete.StatusCode);

        var get = await client.GetAsync($"/api/customers/{customer.Id}");
        Assert.Equal(HttpStatusCode.NotFound, get.StatusCode);

        var list = await GetCustomersAsync(client);
        Assert.DoesNotContain(list, c => c.Id == customer.Id);
    }

    [Fact]
    public async Task LedgerTransactions_AreImmutable_UpdateIsRejected()
    {
        var client = await CreateOwnerClientAsync();
        var customer = await CreateCustomerAsync(client, $"Immutable {Guid.NewGuid():n}",
            openingBalance: 75000);

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<KhataDbContext>();

        var account = await db.LedgerAccounts.IgnoreQueryFilters()
            .FirstAsync(a => a.PartyType == PartyType.Customer && a.PartyId == customer.Id);
        var txn = await db.LedgerTransactions.IgnoreQueryFilters()
            .FirstAsync(t => t.LedgerAccountId == account.Id);

        txn.Description = "rewritten history";
        var updateError = await Assert.ThrowsAsync<InvalidOperationException>(
            () => db.SaveChangesAsync());
        Assert.Contains("immutable", updateError.Message);

        // Reset, then attempt a hard delete.
        txn.Description = null;
        db.Entry(txn).State = EntityState.Unchanged;
        db.LedgerTransactions.Remove(txn);
        var deleteError = await Assert.ThrowsAsync<InvalidOperationException>(
            () => db.SaveChangesAsync());
        Assert.Contains("immutable", deleteError.Message);

        // Stored row unchanged — still the original opening description.
        db.Entry(txn).State = EntityState.Detached;
        var stored = await db.LedgerTransactions.IgnoreQueryFilters()
            .AsNoTracking()
            .FirstAsync(t => t.Id == txn.Id);
        Assert.Equal("Opening balance", stored.Description);
    }

    [Fact]
    public async Task OtherBusiness_CannotSeeCustomer_OrItsLedger_Returns404()
    {
        var ownerA = await CreateOwnerClientAsync();
        var customerA = await CreateCustomerAsync(ownerA, $"Private {Guid.NewGuid():n}",
            openingBalance: 90000);

        var ownerB = await CreateOwnerClientAsync();
        await CreateCustomerAsync(ownerB, $"Theirs {Guid.NewGuid():n}", openingBalance: 1000);

        var get = await ownerB.GetAsync($"/api/customers/{customerA.Id}");
        Assert.Equal(HttpStatusCode.NotFound, get.StatusCode);

        var ledger = await ownerB.GetAsync($"/api/customers/{customerA.Id}/ledger");
        Assert.Equal(HttpStatusCode.NotFound, ledger.StatusCode);

        var list = await GetCustomersAsync(ownerB);
        Assert.DoesNotContain(list, c => c.Id == customerA.Id);
    }

    [Fact]
    public async Task UnknownCustomer_Returns404()
    {
        var client = await CreateOwnerClientAsync();

        var get = await client.GetAsync("/api/customers/999999");
        Assert.Equal(HttpStatusCode.NotFound, get.StatusCode);

        var ledger = await client.GetAsync("/api/customers/999999/ledger");
        Assert.Equal(HttpStatusCode.NotFound, ledger.StatusCode);
    }

    // --- helpers ---

    private static async Task<CustomerDto> CreateCustomerAsync(
        HttpClient client, string name, long openingBalance = 0, string? phoneNumber = null)
    {
        var response = await client.PostAsJsonAsync("/api/customers", new
        {
            name,
            phoneNumber,
            openingBalance,
        });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<CustomerDto>(JsonOptions))!;
    }

    private static async Task UpdateOpeningAsync(
        HttpClient client, string basePath, long id, string name, long openingBalance)
    {
        var response = await client.PutAsJsonAsync($"{basePath}/{id}", new
        {
            name,
            openingBalance,
        });
        response.EnsureSuccessStatusCode();
    }

    private static async Task<List<CustomerDto>> GetCustomersAsync(HttpClient client, string? search = null)
    {
        var url = string.IsNullOrEmpty(search)
            ? "/api/customers?pageSize=100"
            : $"/api/customers?search={Uri.EscapeDataString(search)}&pageSize=100";
        var page = await client.GetFromJsonAsync<PagedResult<CustomerDto>>(url, JsonOptions);
        return page!.Data.ToList();
    }

    private static async Task<PartyLedgerDto> GetLedgerAsync(HttpClient client, long customerId)
    {
        var ledger = await client.GetFromJsonAsync<PartyLedgerDto>(
            $"/api/customers/{customerId}/ledger?pageSize=100", JsonOptions);
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
