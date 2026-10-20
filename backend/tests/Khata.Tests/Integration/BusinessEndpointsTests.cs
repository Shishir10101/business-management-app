using System.IdentityModel.Tokens.Jwt;
using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Khata.Application.DTOs;
using Khata.Tests.Testing;
using Xunit;

namespace Khata.Tests.Integration;

[Collection(ApiTestCollection.Name)]
public class BusinessEndpointsTests
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);
    private readonly KhataApiFactory _factory;

    public BusinessEndpointsTests(KhataApiFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task CreateBusiness_MakesUserOwner_AndIncludesInList()
    {
        var client = await CreateOwnerClientAsync();

        var created = await CreateBusinessAsync(client, $"Shop {Guid.NewGuid():n}");

        Assert.NotEqual(0, created.Id);
        Assert.Equal("Owner", created.Role);
        Assert.Equal("NPR", created.Currency);

        var list = await client.GetFromJsonAsync<List<BusinessDto>>("/api/businesses", JsonOptions);
        Assert.Contains(list!, b => b.Id == created.Id);

        var fetched = await client.GetFromJsonAsync<BusinessDto>($"/api/businesses/{created.Id}", JsonOptions);
        Assert.Equal(created.Name, fetched!.Name);
    }

    [Fact]
    public async Task CreateBusiness_WithEmptyName_ReturnsValidationProblemDetails()
    {
        var client = await CreateOwnerClientAsync();

        var response = await client.PostAsJsonAsync("/api/businesses", new
        {
            name = "",
            currency = "NPR",
        });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task SwitchBusiness_IssuesTokenCarryingBusinessIdAndOwnerPermissions()
    {
        var client = await CreateOwnerClientAsync();
        var business = await CreateBusinessAsync(client, $"Switch Shop {Guid.NewGuid():n}");

        var switched = await client.PostAsJsonAsync($"/api/businesses/{business.Id}/switch", new { });

        Assert.Equal(HttpStatusCode.OK, switched.StatusCode);
        var auth = await switched.Content.ReadFromJsonAsync<AuthResponse>(JsonOptions);
        Assert.NotNull(auth!.AccessToken);

        var jwt = new JwtSecurityTokenHandler().ReadJwtToken(auth.AccessToken);
        Assert.Equal(business.Id.ToString(), jwt.Claims.First(c => c.Type == "bid").Value);
        Assert.Contains(jwt.Claims, c => c.Type == "perms" && c.Value == "sales.view");
        Assert.Contains(jwt.Claims, c => c.Type == "perms" && c.Value == "settings.manage");

        // Owner permission granted through the new token → member list is accessible.
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", auth.AccessToken);
        var members = await client.GetFromJsonAsync<List<BusinessMemberDto>>(
            $"/api/businesses/{business.Id}/members", JsonOptions);
        Assert.Single(members!);
        Assert.Equal("Owner", members![0].Role);
    }

    [Fact]
    public async Task NonMember_AccessingBusiness_Returns404()
    {
        var ownerClient = await CreateOwnerClientAsync();
        var business = await CreateBusinessAsync(ownerClient, $"Private Shop {Guid.NewGuid():n}");

        var outsider = await AuthEndpointsTests.CreateAuthenticatedClientAsync(_factory);

        var response = await outsider.GetAsync($"/api/businesses/{business.Id}");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task ManagerRole_CannotUpdateBusinessSettings_ButOwnerCan()
    {
        var ownerClient = await CreateOwnerClientAsync();
        var business = await CreateBusinessAsync(ownerClient, $"Team Shop {Guid.NewGuid():n}");

        // Invite a Manager.
        var manager = await AuthEndpointsTests.CreateAuthenticatedClientAsync(_factory);
        var managerEmail = $"mgr_{Guid.NewGuid():n}@test.local";
        await AuthEndpointsTests.CreateAuthenticatedClientAsync(_factory, managerEmail);
        var invite = await ownerClient.PostAsJsonAsync($"/api/businesses/{business.Id}/members",
            new { email = managerEmail, role = "Manager" });
        Assert.Equal(HttpStatusCode.Created, invite.StatusCode);

        // Manager logs in, switches to the business, then tries to update settings.
        var managerClient = await LoginAsync(managerEmail);
        await managerClient.PostAsJsonAsync($"/api/businesses/{business.Id}/switch", new { });

        var forbidden = await managerClient.PutAsJsonAsync($"/api/businesses/{business.Id}",
            UpdatePayload(business.Name + " v2"));
        Assert.Equal(HttpStatusCode.Forbidden, forbidden.StatusCode);

        // Owner's update succeeds.
        var ok = await ownerClient.PutAsJsonAsync($"/api/businesses/{business.Id}",
            UpdatePayload(business.Name + " v2"));
        Assert.Equal(HttpStatusCode.OK, ok.StatusCode);
        var updated = await ok.Content.ReadFromJsonAsync<BusinessDto>(JsonOptions);
        Assert.Equal(business.Name + " v2", updated!.Name);
    }

    [Fact]
    public async Task InvitedMember_SeesBusinessInTheirList_AndAppearsInMembers()
    {
        var ownerClient = await CreateOwnerClientAsync();
        var business = await CreateBusinessAsync(ownerClient, $"Staff Shop {Guid.NewGuid():n}");

        var staffEmail = $"staff_{Guid.NewGuid():n}@test.local";
        await AuthEndpointsTests.CreateAuthenticatedClientAsync(_factory, staffEmail);

        var invite = await ownerClient.PostAsJsonAsync($"/api/businesses/{business.Id}/members",
            new { email = staffEmail, role = "SalesStaff" });
        Assert.Equal(HttpStatusCode.Created, invite.StatusCode);

        var staffClient = await LoginAsync(staffEmail);
        var list = await staffClient.GetFromJsonAsync<List<BusinessDto>>("/api/businesses", JsonOptions);
        Assert.Contains(list!, b => b.Id == business.Id);
        Assert.Equal("SalesStaff", list!.Single(b => b.Id == business.Id).Role);

        var members = await ownerClient.GetFromJsonAsync<List<BusinessMemberDto>>(
            $"/api/businesses/{business.Id}/members", JsonOptions);
        Assert.Equal(2, members!.Count);
    }

    [Fact]
    public async Task Invite_WithUnknownEmail_Returns404()
    {
        var ownerClient = await CreateOwnerClientAsync();
        var business = await CreateBusinessAsync(ownerClient, $"Ghost Shop {Guid.NewGuid():n}");

        var invite = await ownerClient.PostAsJsonAsync($"/api/businesses/{business.Id}/members",
            new { email = $"ghost_{Guid.NewGuid():n}@test.local", role = "Viewer" });

        Assert.Equal(HttpStatusCode.NotFound, invite.StatusCode);
    }

    [Fact]
    public async Task Invite_WithDuplicateMembership_Returns409()
    {
        var ownerClient = await CreateOwnerClientAsync();
        var business = await CreateBusinessAsync(ownerClient, $"Dup Shop {Guid.NewGuid():n}");

        var staffEmail = $"dupe_{Guid.NewGuid():n}@test.local";
        await AuthEndpointsTests.CreateAuthenticatedClientAsync(_factory, staffEmail);

        await ownerClient.PostAsJsonAsync($"/api/businesses/{business.Id}/members",
            new { email = staffEmail, role = "Viewer" });
        var second = await ownerClient.PostAsJsonAsync($"/api/businesses/{business.Id}/members",
            new { email = staffEmail, role = "Viewer" });

        Assert.Equal(HttpStatusCode.Conflict, second.StatusCode);
    }

    [Fact]
    public async Task RemoveMember_SoftDeletesMembership()
    {
        var ownerClient = await CreateOwnerClientAsync();
        var business = await CreateBusinessAsync(ownerClient, $"Churn Shop {Guid.NewGuid():n}");

        var staffEmail = $"leaver_{Guid.NewGuid():n}@test.local";
        await AuthEndpointsTests.CreateAuthenticatedClientAsync(_factory, staffEmail);
        var invite = await ownerClient.PostAsJsonAsync($"/api/businesses/{business.Id}/members",
            new { email = staffEmail, role = "Viewer" });
        var member = await invite.Content.ReadFromJsonAsync<BusinessMemberDto>(JsonOptions);

        var remove = await ownerClient.DeleteAsync($"/api/businesses/{business.Id}/members/{member!.Id}");
        Assert.Equal(HttpStatusCode.NoContent, remove.StatusCode);

        var members = await ownerClient.GetFromJsonAsync<List<BusinessMemberDto>>(
            $"/api/businesses/{business.Id}/members", JsonOptions);
        Assert.DoesNotContain(members!, m => m.Id == member.Id);
    }

    [Fact]
    public async Task LastOwner_CannotBeRemovedOrDemoted()
    {
        var ownerClient = await CreateOwnerClientAsync();
        var business = await CreateBusinessAsync(ownerClient, $"Solo Shop {Guid.NewGuid():n}");

        var members = await ownerClient.GetFromJsonAsync<List<BusinessMemberDto>>(
            $"/api/businesses/{business.Id}/members", JsonOptions);
        var self = members!.Single();

        var remove = await ownerClient.DeleteAsync($"/api/businesses/{business.Id}/members/{self.Id}");
        Assert.Equal(HttpStatusCode.UnprocessableEntity, remove.StatusCode);

        var demote = await ownerClient.PutAsJsonAsync(
            $"/api/businesses/{business.Id}/members/{self.Id}", new { role = "Viewer" });
        Assert.Equal(HttpStatusCode.UnprocessableEntity, demote.StatusCode);
    }

    [Fact]
    public async Task Switch_ToNonMemberBusiness_Returns404()
    {
        var ownerClient = await CreateOwnerClientAsync();
        var business = await CreateBusinessAsync(ownerClient, $"Locked Shop {Guid.NewGuid():n}");

        var outsider = await AuthEndpointsTests.CreateAuthenticatedClientAsync(_factory);

        var response = await outsider.PostAsJsonAsync($"/api/businesses/{business.Id}/switch", new { });

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task DeleteBusiness_OwnerOnly_AndHidesItAfterwards()
    {
        var ownerClient = await CreateOwnerClientAsync();
        var business = await CreateBusinessAsync(ownerClient, $"Temp Shop {Guid.NewGuid():n}");

        var delete = await ownerClient.DeleteAsync($"/api/businesses/{business.Id}");
        Assert.Equal(HttpStatusCode.NoContent, delete.StatusCode);

        var after = await ownerClient.GetAsync($"/api/businesses/{business.Id}");
        Assert.Equal(HttpStatusCode.NotFound, after.StatusCode);

        var list = await ownerClient.GetFromJsonAsync<List<BusinessDto>>("/api/businesses", JsonOptions);
        Assert.DoesNotContain(list!, b => b.Id == business.Id);
    }

    // --- helpers ---

    private static object UpdatePayload(string name) => new
    {
        name,
        type = (string?)null,
        panNumber = (string?)null,
        phoneNumber = (string?)null,
        email = (string?)null,
        addressLine = (string?)null,
        city = (string?)null,
        district = (string?)null,
        province = (string?)null,
        wardNumber = (string?)null,
        logoUrl = (string?)null,
        currency = "NPR",
        isActive = true,
    };

    private static async Task<BusinessDto> CreateBusinessAsync(HttpClient client, string name)
    {
        var response = await client.PostAsJsonAsync("/api/businesses", new
        {
            name,
            currency = "NPR",
        });
        response.EnsureSuccessStatusCode();
        var business = await response.Content.ReadFromJsonAsync<BusinessDto>(JsonOptions);
        Assert.NotNull(business);

        // Switch to the new business so the client's JWT carries the Owner role,
        // permissions, and the business id — same flow the mobile app follows.
        var switchResponse = await client.PostAsJsonAsync($"/api/businesses/{business!.Id}/switch", new { });
        switchResponse.EnsureSuccessStatusCode();
        var auth = await switchResponse.Content.ReadFromJsonAsync<AuthResponse>(JsonOptions);
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", auth!.AccessToken);

        return business;
    }

    // ---------------------------------------------------------------
    // Bank accounts (the previously dead BusinessBankAccount entity)
    // ---------------------------------------------------------------

    [Fact]
    public async Task BankAccounts_AddListDefaultAndDelete()
    {
        var client = await CreateOwnerClientAsync();
        var business = await CreateBusinessAsync(client, $"Bank Shop {Guid.NewGuid():n}");
        var bid = business.Id;

        var empty = await GetBankAccountsAsync(client, bid);
        Assert.Empty(empty);

        var first = await AddBankAccountAsync(client, bid,
            bankName: "Nepal Investment Bank", accountName: "Himalayan Traders",
            accountNumber: "0012345678901", branch: "New Road", isDefault: true);
        Assert.True(first.IsDefault);
        Assert.Equal(0, first.PaymentCount);

        var second = await AddBankAccountAsync(client, bid,
            bankName: "Global IME Bank", accountName: "Himalayan Traders",
            accountNumber: "0098765432101", isDefault: true);

        // Only one default: promoting the second clears the first.
        var listed = await GetBankAccountsAsync(client, bid);
        Assert.Equal(2, listed.Count);
        Assert.Single(listed, a => a.IsDefault);
        Assert.Equal(second.Id, listed.First(a => a.IsDefault).Id);

        await RemoveBankAccountAsync(client, bid, second.Id);
        var afterDelete = await GetBankAccountsAsync(client, bid);
        Assert.Single(afterDelete);
        Assert.Equal(first.Id, afterDelete[0].Id);
    }

    [Fact]
    public async Task BankAccounts_MissingAccountNumber_ReturnsValidationProblem()
    {
        var client = await CreateOwnerClientAsync();
        var business = await CreateBusinessAsync(client, $"No Acct Shop {Guid.NewGuid():n}");

        var response = await client.PostAsJsonAsync(
            $"/api/businesses/{business.Id}/bank-accounts",
            new { bankName = "NIC Asia", accountName = "Shop", accountNumber = "" });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task BankAccounts_NonMember_CannotReadThem()
    {
        var owner = await CreateOwnerClientAsync();
        var business = await CreateBusinessAsync(owner, $"Private Bank Shop {Guid.NewGuid():n}");
        await AddBankAccountAsync(owner, business.Id,
            bankName: "NIC Asia", accountName: "Shop", accountNumber: "1234567890");

        // The stranger needs a business of their own first: without one their
        // token carries no settings permission at all, and the authorization
        // policy answers 403 before the membership check ever runs.
        var stranger = await AuthEndpointsTests.CreateAuthenticatedClientAsync(_factory);
        await CreateBusinessAsync(stranger, $"Stranger Bank Shop {Guid.NewGuid():n}");

        var response = await stranger.GetAsync(
            $"/api/businesses/{business.Id}/bank-accounts");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    private static async Task<List<BankAccountDto>> GetBankAccountsAsync(
        HttpClient client, long businessId)
    {
        var response = await client.GetAsync($"/api/businesses/{businessId}/bank-accounts");
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<List<BankAccountDto>>(JsonOptions))!;
    }

    private static async Task<BankAccountDto> AddBankAccountAsync(
        HttpClient client, long businessId, string bankName, string accountName,
        string accountNumber, string? branch = null, bool isDefault = false)
    {
        var response = await client.PostAsJsonAsync(
            $"/api/businesses/{businessId}/bank-accounts",
            new { bankName, accountName, accountNumber, branch, isDefault });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<BankAccountDto>(JsonOptions))!;
    }

    private static async Task RemoveBankAccountAsync(
        HttpClient client, long businessId, long accountId)
    {
        var response = await client.DeleteAsync(
            $"/api/businesses/{businessId}/bank-accounts/{accountId}");
        response.EnsureSuccessStatusCode();
    }

    /// <summary>Logs in an already-registered user and returns a bearer-authorized client.</summary>
    private async Task<HttpClient> LoginAsync(string email)
    {
        var client = _factory.CreateClient();
        var login = await client.PostAsJsonAsync("/api/auth/login", new { email, password = "Passw0rd123" });
        login.EnsureSuccessStatusCode();
        var auth = await login.Content.ReadFromJsonAsync<AuthResponse>(JsonOptions);
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", auth!.AccessToken);
        return client;
    }

    private async Task<HttpClient> CreateOwnerClientAsync() =>
        await AuthEndpointsTests.CreateAuthenticatedClientAsync(_factory);
}
