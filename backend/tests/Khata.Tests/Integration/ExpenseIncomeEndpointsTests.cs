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

/// <summary>Expenses and income: CRUD, validation, filtering, soft delete, isolation.</summary>
[Collection(ApiTestCollection.Name)]
public class ExpenseIncomeEndpointsTests
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web)
    {
        Converters = { new JsonStringEnumConverter() },
    };

    private readonly KhataApiFactory _factory;

    public ExpenseIncomeEndpointsTests(KhataApiFactory factory)
    {
        _factory = factory;
    }

    // --- Expenses ---

    [Fact]
    public async Task CreateExpense_Returns201_AndAppearsInList()
    {
        var client = await CreateOwnerClientAsync();

        var expense = await CreateExpenseAsync(client, "Rent", 2500000, "Shop rent");

        Assert.True(expense.Id > 0);
        Assert.Equal("Rent", expense.Category);
        Assert.Equal(2500000, expense.Amount);

        var list = await GetExpensesAsync(client);
        Assert.Contains(list, e => e.Id == expense.Id);
    }

    [Fact]
    public async Task CreateExpense_WithZeroAmount_Returns400()
    {
        var client = await CreateOwnerClientAsync();

        var response = await client.PostAsJsonAsync("/api/expenses", new
        {
            category = "Rent",
            amount = 0L,
        });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task CreateExpense_WithEmptyCategory_Returns400()
    {
        var client = await CreateOwnerClientAsync();

        var response = await client.PostAsJsonAsync("/api/expenses", new
        {
            category = "",
            amount = 100L,
        });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task UpdateExpense_ChangesFields()
    {
        var client = await CreateOwnerClientAsync();
        var expense = await CreateExpenseAsync(client, "Utilities", 100000, "Electric");

        var update = await client.PutAsJsonAsync($"/api/expenses/{expense.Id}", new
        {
            category = "Utilities",
            amount = 175000L,
            description = "Electric + water",
        });
        update.EnsureSuccessStatusCode();
        var updated = await update.Content.ReadFromJsonAsync<ExpenseDto>(JsonOptions);

        Assert.Equal(175000, updated!.Amount);
        Assert.Equal("Electric + water", updated.Description);
    }

    [Fact]
    public async Task DeleteExpense_SoftDeletes_AndHidesFromList()
    {
        var client = await CreateOwnerClientAsync();
        var expense = await CreateExpenseAsync(client, "Misc", 5000, null);

        var delete = await client.DeleteAsync($"/api/expenses/{expense.Id}");
        Assert.Equal(HttpStatusCode.NoContent, delete.StatusCode);

        var get = await client.GetAsync($"/api/expenses/{expense.Id}");
        Assert.Equal(HttpStatusCode.NotFound, get.StatusCode);

        var list = await GetExpensesAsync(client);
        Assert.DoesNotContain(list, e => e.Id == expense.Id);
    }

    [Fact]
    public async Task GetExpenses_FiltersByCategoryAndSearch()
    {
        var client = await CreateOwnerClientAsync();
        var suffix = Guid.NewGuid().ToString("n")[..8];
        await CreateExpenseAsync(client, "Salary", 500000, $"Staff {suffix}");
        await CreateExpenseAsync(client, "Transport", 3000, "Delivery");

        var byCategory = await GetExpensesAsync(client, "category=Salary");
        Assert.All(byCategory, e => Assert.Equal("Salary", e.Category));

        var bySearch = await GetExpensesAsync(client, $"search={suffix}");
        Assert.Single(bySearch);
        Assert.Contains(suffix, bySearch[0].Description!);
    }

    [Fact]
    public async Task UnknownExpense_Returns404()
    {
        var client = await CreateOwnerClientAsync();

        var get = await client.GetAsync("/api/expenses/999999");
        Assert.Equal(HttpStatusCode.NotFound, get.StatusCode);
    }

    [Fact]
    public async Task OtherBusiness_CannotSeeExpense_Returns404()
    {
        var ownerA = await CreateOwnerClientAsync();
        var expenseA = await CreateExpenseAsync(ownerA, "Rent", 100000, null);

        var ownerB = await CreateOwnerClientAsync();

        var get = await ownerB.GetAsync($"/api/expenses/{expenseA.Id}");
        Assert.Equal(HttpStatusCode.NotFound, get.StatusCode);
        Assert.DoesNotContain(await GetExpensesAsync(ownerB), e => e.Id == expenseA.Id);
    }

    // --- Income ---

    [Fact]
    public async Task CreateIncome_Returns201_AndUpdateDeleteWork()
    {
        var client = await CreateOwnerClientAsync();

        var create = await client.PostAsJsonAsync("/api/incomes", new
        {
            source = "Interest",
            amount = 45000L,
            description = "Bank interest",
        });
        create.EnsureSuccessStatusCode();
        var income = await create.Content.ReadFromJsonAsync<IncomeDto>(JsonOptions);
        Assert.Equal("Interest", income!.Source);
        Assert.Equal(45000, income.Amount);

        var update = await client.PutAsJsonAsync($"/api/incomes/{income.Id}", new
        {
            source = "Interest",
            amount = 52000L,
        });
        update.EnsureSuccessStatusCode();
        var updated = await update.Content.ReadFromJsonAsync<IncomeDto>(JsonOptions);
        Assert.Equal(52000, updated!.Amount);

        var delete = await client.DeleteAsync($"/api/incomes/{income.Id}");
        Assert.Equal(HttpStatusCode.NoContent, delete.StatusCode);

        var get = await client.GetAsync($"/api/incomes/{income.Id}");
        Assert.Equal(HttpStatusCode.NotFound, get.StatusCode);
    }

    [Fact]
    public async Task CreateIncome_WithZeroAmount_Returns400()
    {
        var client = await CreateOwnerClientAsync();

        var response = await client.PostAsJsonAsync("/api/incomes", new
        {
            source = "Interest",
            amount = 0L,
        });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    // --- helpers ---

    private static async Task<ExpenseDto> CreateExpenseAsync(
        HttpClient client, string category, long amount, string? description)
    {
        var response = await client.PostAsJsonAsync("/api/expenses", new
        {
            category,
            amount,
            description,
        });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<ExpenseDto>(JsonOptions))!;
    }

    private static async Task<List<ExpenseDto>> GetExpensesAsync(HttpClient client, string? query = null)
    {
        var url = "/api/expenses?pageSize=100" + (query is null ? "" : "&" + query);
        var page = await client.GetFromJsonAsync<PagedResult<ExpenseDto>>(url, JsonOptions);
        return page!.Data.ToList();
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
