using System.IdentityModel.Tokens.Jwt;
using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Infrastructure.Identity;
using Khata.Tests.Testing;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Khata.Tests.Integration;

/// <summary>
/// Regression tests for the flaws found by the security / penetration pass.
/// Each one pins a specific control that was missing or bypassable, so a later
/// refactor cannot quietly reopen it.
/// </summary>
[Collection(ApiTestCollection.Name)]
public class SecurityRegressionTests
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web)
    {
        Converters = { new JsonStringEnumConverter() },
    };

    private readonly KhataApiFactory _factory;

    public SecurityRegressionTests(KhataApiFactory factory)
    {
        _factory = factory;
    }

    // ---------------------------------------------------------------
    // Account enumeration
    // ---------------------------------------------------------------

    [Fact]
    public async Task Register_WithAnExistingEmail_DoesNotEchoTheAddressBack()
    {
        var (client, _, email) = await CreateOwnerAsync();

        var response = await client.PostAsJsonAsync("/api/auth/register", new
        {
            fullName = "Second Attempt",
            email,
            password = "Passw0rd123",
            phoneNumber = (string?)null,
        });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();

        // Confirming "this address is registered" turns the form into an
        // account oracle for a leaked address list.
        Assert.DoesNotContain(email, body, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("already registered", body, StringComparison.OrdinalIgnoreCase);
    }

    // ---------------------------------------------------------------
    // Locale + password policy
    // ---------------------------------------------------------------

    [Fact]
    public async Task Register_WithHindiLocale_IsAccepted()
    {
        // The mobile app ships a Hindi translation; the validator only knew
        // "ne" and "en", so a Hindi device could not create an account at all.
        var response = await _factory.CreateClient().PostAsJsonAsync("/api/auth/register", new
        {
            fullName = "Hindi User",
            email = $"hindi-{Guid.NewGuid():n}@khata.local",
            password = "Passw0rd123",
            phoneNumber = (string?)null,
            locale = "hi",
        });

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }

    [Fact]
    public async Task Register_WithNineCharacterPassword_IsRejectedByValidation()
    {
        // Below Identity's RequiredLength (10). The validator used to accept it
        // and the user got Identity's generic policy text instead.
        var response = await _factory.CreateClient().PostAsJsonAsync("/api/auth/register", new
        {
            fullName = "Short Password",
            email = $"short-{Guid.NewGuid():n}@khata.local",
            password = "Passw0rd1",
            phoneNumber = (string?)null,
        });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.Contains("10 characters", body, StringComparison.OrdinalIgnoreCase);
    }

    // ---------------------------------------------------------------
    // Session lifecycle
    // ---------------------------------------------------------------

    [Fact]
    public async Task Login_HonoursTheSelectedActiveBusiness()
    {
        var (client, _, email) = await CreateOwnerAsync();

        var first = await CreateBusinessAsync(client, $"First {Guid.NewGuid():n}");
        var second = await CreateBusinessAsync(client, $"Second {Guid.NewGuid():n}");

        // CreateBusinessAsync switches to the business it just made, so the
        // second one is the selection at this point.
        var login = await _factory.CreateClient()
            .PostAsJsonAsync("/api/auth/login", new { email, password = "Passw0rd123" });
        login.EnsureSuccessStatusCode();
        var auth = (await login.Content.ReadFromJsonAsync<AuthResponse>(JsonOptions))!;

        var token = new JwtSecurityTokenHandler().ReadJwtToken(auth.AccessToken);
        var bid = token.Claims.First(c => c.Type == "bid").Value;

        // The old code always took businesses[0], so a shop that had switched
        // silently reopened in its first business on every sign-in.
        Assert.Equal(second.Id.ToString(), bid);
        Assert.NotEqual(first.Id.ToString(), bid);
    }

    [Fact]
    public async Task ChangePassword_RevokesEveryRefreshToken()
    {
        var (client, auth, _) = await CreateOwnerAsync();

        var change = await client.PostAsJsonAsync("/api/auth/change-password", new
        {
            currentPassword = "Passw0rd123",
            newPassword = "Passw0rd456",
        });
        Assert.Equal(HttpStatusCode.NoContent, change.StatusCode);

        var refresh = await _factory.CreateClient().PostAsJsonAsync(
            "/api/auth/refresh", new { refreshToken = auth.RefreshToken });

        // A stolen session must not survive the password change that was made
        // to contain it.
        Assert.Equal(HttpStatusCode.Unauthorized, refresh.StatusCode);
    }

    [Fact]
    public async Task SuspendedUser_CannotRefreshAndItsAccessTokenStopsWorking()
    {
        var (ownerClient, ownerAuth, _) = await CreateOwnerAsync();
        var admin = await CreateSuperAdminClientAsync();

        var suspend = await admin.PostAsJsonAsync(
            $"/api/admin/users/{ownerAuth.UserId}/suspend", new { reason = "probe" });
        suspend.EnsureSuccessStatusCode();

        var refresh = await _factory.CreateClient().PostAsJsonAsync(
            "/api/auth/refresh", new { refreshToken = ownerAuth.RefreshToken });
        Assert.Equal(HttpStatusCode.Unauthorized, refresh.StatusCode);

        // The access token is still cryptographically valid, so the request
        // pipeline has to consult the account state.
        var me = await ownerClient.GetAsync("/api/auth/me");
        Assert.Equal(HttpStatusCode.Unauthorized, me.StatusCode);

        await admin.PostAsJsonAsync(
            $"/api/admin/users/{ownerAuth.UserId}/activate", new { reason = "cleanup" });
    }

    // ---------------------------------------------------------------
    // Platform suspension actually applies
    // ---------------------------------------------------------------

    [Fact]
    public async Task SuspendedBusiness_IsRefused_ButTheOwnerCanStillRecover()
    {
        var (ownerClient, _, _) = await CreateOwnerAsync();
        var business = await CreateBusinessAsync(ownerClient, $"Suspendable {Guid.NewGuid():n}");
        var admin = await CreateSuperAdminClientAsync();

        var suspend = await admin.PostAsJsonAsync(
            $"/api/admin/businesses/{business.Id}/suspend", new { reason = "tos" });
        suspend.EnsureSuccessStatusCode();

        var data = await ownerClient.GetAsync("/api/customers");
        Assert.Equal(HttpStatusCode.Forbidden, data.StatusCode);

        // ...but the recovery screen still works, otherwise the client is
        // locked out of the only place it can switch businesses.
        var list = await ownerClient.GetAsync("/api/businesses");
        Assert.Equal(HttpStatusCode.OK, list.StatusCode);

        await admin.PostAsJsonAsync(
            $"/api/admin/businesses/{business.Id}/activate", new { reason = "cleanup" });
    }

    [Fact]
    public async Task TenantAdmin_CannotChangeThePlatformSuspensionFlag()
    {
        var (ownerClient, _, _) = await CreateOwnerAsync();
        var business = await CreateBusinessAsync(ownerClient, $"Flag Shop {Guid.NewGuid():n}");
        var admin = await CreateSuperAdminClientAsync();

        await admin.PostAsJsonAsync(
            $"/api/admin/businesses/{business.Id}/suspend", new { reason = "tos" });

        // The tenant PUTs isActive=true in the hope of un-suspending itself.
        var put = await ownerClient.PutAsJsonAsync($"/api/businesses/{business.Id}", new
        {
            name = business.Name,
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
        });
        put.EnsureSuccessStatusCode();

        var stillSuspended = await ownerClient.GetAsync("/api/customers");
        Assert.Equal(HttpStatusCode.Forbidden, stillSuspended.StatusCode);

        await admin.PostAsJsonAsync(
            $"/api/admin/businesses/{business.Id}/activate", new { reason = "cleanup" });
    }

    // ---------------------------------------------------------------
    // Privilege escalation
    // ---------------------------------------------------------------

    [Fact]
    public async Task Admin_CannotPromoteItselfOrAnyoneElseToOwner()
    {
        var (ownerClient, _, _) = await CreateOwnerAsync();
        var business = await CreateBusinessAsync(ownerClient, $"Roles {Guid.NewGuid():n}");

        var adminEmail = $"admin-{Guid.NewGuid():n}@khata.local";
        await RegisterOnlyAsync(adminEmail);
        await InviteAsync(ownerClient, business.Id, adminEmail, "Admin");
        var adminClient = await LoginAsync(adminEmail);

        var members = await adminClient.GetFromJsonAsync<List<BusinessMemberDto>>(
            $"/api/businesses/{business.Id}/members", JsonOptions);
        var me = members!.Single(m => m.Email == adminEmail);

        var promote = await adminClient.PutAsJsonAsync(
            $"/api/businesses/{business.Id}/members/{me.Id}", new { role = "Owner" });
        Assert.Equal(HttpStatusCode.Forbidden, promote.StatusCode);

        var invite = await adminClient.PostAsJsonAsync(
            $"/api/businesses/{business.Id}/members",
            new { email = $"accomplice-{Guid.NewGuid():n}@khata.local", role = "Owner" });
        Assert.Equal(HttpStatusCode.Forbidden, invite.StatusCode);
    }

    [Fact]
    public async Task SalesStaff_CannotWriteOtherEntitiesThroughSyncPush()
    {
        var (ownerClient, _, _) = await CreateOwnerAsync();
        var business = await CreateBusinessAsync(ownerClient, $"Sync Roles {Guid.NewGuid():n}");

        var staffEmail = $"staff-{Guid.NewGuid():n}@khata.local";
        await RegisterOnlyAsync(staffEmail);
        await InviteAsync(ownerClient, business.Id, staffEmail, "SalesStaff");
        var staff = await LoginAsync(staffEmail);

        // SalesStaff holds sync.use but not products.edit / expenses.create.
        // Push multiplexes every entity, so it must re-check the entity right.
        var push = await staff.PostAsJsonAsync("/api/sync/push", new
        {
            operations = new object[]
            {
                new
                {
                    operationId = Guid.NewGuid().ToString("n"),
                    entityType = "product",
                    operation = "delete",
                    entityId = 1L,
                    payload = (object?)null,
                },
                new
                {
                    operationId = Guid.NewGuid().ToString("n"),
                    entityType = "expense",
                    operation = "create",
                    entityId = 0L,
                    payload = new { category = "Rent", amount = 100_000L, expenseDate = "2026-10-20" },
                },
            },
        });
        push.EnsureSuccessStatusCode();

        var result = (await push.Content.ReadFromJsonAsync<SyncPushResultDto>(JsonOptions))!;
        Assert.All(result.Results, op => Assert.NotEqual("applied", op.Status));
        Assert.All(result.Results, op => Assert.Contains("permission", op.Error!));
    }

    // ---------------------------------------------------------------
    // Public statement links
    // ---------------------------------------------------------------

    [Fact]
    public async Task StatementLink_TtlIsBounded_AndDoesNotCrash()
    {
        var (client, _, _) = await CreateOwnerAsync();
        await CreateBusinessAsync(client, $"Statements {Guid.NewGuid():n}");
        var customer = await CreateCustomerAsync(client);

        var huge = await client.PostAsJsonAsync(
            $"/api/customers/{customer.Id}/statement-link?ttlDays={int.MaxValue}", new { });
        Assert.Equal(HttpStatusCode.OK, huge.StatusCode);
        var link = (await huge.Content.ReadFromJsonAsync<StatementLinkResponse>(JsonOptions))!;
        Assert.True(link.ExpiresAt <= DateTimeOffset.UtcNow.AddDays(91),
            $"a shared ledger must not be public forever (expires {link.ExpiresAt:O})");

        var overflow = await client.PostAsJsonAsync(
            $"/api/customers/{customer.Id}/statement-link?ttlDays={int.MinValue}", new { });
        Assert.NotEqual(HttpStatusCode.InternalServerError, overflow.StatusCode);
    }

    // ---------------------------------------------------------------
    // Response hygiene
    // ---------------------------------------------------------------

    [Fact]
    public async Task ReportExport_NeutralisesSpreadsheetFormulaInjection()
    {
        var (client, _, _) = await CreateOwnerAsync();
        await CreateBusinessAsync(client, $"CSV {Guid.NewGuid():n}");

        var create = await client.PostAsJsonAsync("/api/expenses", new
        {
            category = "Rent",
            description = "=HYPERLINK(\"http://evil.example\",\"open\")",
            amount = 10_000L,
            expenseDate = "2026-10-20",
        });
        create.EnsureSuccessStatusCode();

        var export = await client.GetAsync(
            "/api/reports/export?type=expenses&dateFrom=2026-10-01&dateTo=2026-10-31");
        export.EnsureSuccessStatusCode();
        var csv = await export.Content.ReadAsStringAsync();

        // A cell beginning with "=" runs as a formula when the accountant opens
        // the export. It must be written as text, not as a formula.
        Assert.DoesNotContain(",=HYPERLINK", csv);
        Assert.Contains("'=HYPERLINK", csv);
    }

    [Fact]
    public async Task Health_DoesNotDiscloseStackOrDatabaseDetails()
    {
        var response = await _factory.CreateClient().GetAsync("/health");
        var body = await response.Content.ReadAsStringAsync();

        Assert.DoesNotContain("provider", body, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("Microsoft.EntityFrameworkCore", body, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("\"database\"", body, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task Responses_DoNotAdvertiseTheServer()
    {
        var response = await _factory.CreateClient().GetAsync("/health");

        Assert.False(response.Headers.Contains("Server"),
            "Kestrel's Server header is a free fingerprint for an attacker");
    }

    // ---------------------------------------------------------------
    // Helpers
    // ---------------------------------------------------------------

    private async Task<(HttpClient client, AuthResponse auth, string email)> CreateOwnerAsync()
    {
        var email = $"owner-{Guid.NewGuid():n}@khata.local";
        var client = _factory.CreateClient();

        var register = await client.PostAsJsonAsync("/api/auth/register", new
        {
            fullName = "Shop Owner",
            email,
            password = "Passw0rd123",
            phoneNumber = (string?)null,
        });
        register.EnsureSuccessStatusCode();
        var auth = (await register.Content.ReadFromJsonAsync<AuthResponse>(JsonOptions))!;
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", auth.AccessToken);

        return (client, auth, email);
    }

    private async Task<BusinessDto> CreateBusinessAsync(HttpClient client, string name)
    {
        var create = await client.PostAsJsonAsync("/api/businesses", new { name, currency = "NPR" });
        create.EnsureSuccessStatusCode();
        var business = (await create.Content.ReadFromJsonAsync<BusinessDto>(JsonOptions))!;

        var switchResponse = await client.PostAsJsonAsync(
            $"/api/businesses/{business.Id}/switch", new { });
        switchResponse.EnsureSuccessStatusCode();
        var auth = (await switchResponse.Content.ReadFromJsonAsync<AuthResponse>(JsonOptions))!;
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", auth.AccessToken);

        return business;
    }

    private async Task RegisterOnlyAsync(string email)
    {
        var response = await _factory.CreateClient().PostAsJsonAsync("/api/auth/register", new
        {
            fullName = "Invitee",
            email,
            password = "Passw0rd123",
            phoneNumber = (string?)null,
        });
        response.EnsureSuccessStatusCode();
    }

    private static async Task InviteAsync(
        HttpClient client, long businessId, string email, string role)
    {
        var response = await client.PostAsJsonAsync(
            $"/api/businesses/{businessId}/members", new { email, role });
        response.EnsureSuccessStatusCode();
    }

    private async Task<HttpClient> LoginAsync(string email)
    {
        var client = _factory.CreateClient();
        var login = await client.PostAsJsonAsync(
            "/api/auth/login", new { email, password = "Passw0rd123" });
        login.EnsureSuccessStatusCode();
        var auth = (await login.Content.ReadFromJsonAsync<AuthResponse>(JsonOptions))!;
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", auth.AccessToken);
        return client;
    }

    private async Task<CustomerDto> CreateCustomerAsync(HttpClient client)
    {
        var response = await client.PostAsJsonAsync(
            "/api/customers", new { name = $"Customer {Guid.NewGuid():n}" });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<CustomerDto>(JsonOptions))!;
    }

    private async Task<HttpClient> CreateSuperAdminClientAsync()
    {
        var (client, auth, email) = await CreateOwnerAsync();

        using (var scope = _factory.Services.CreateScope())
        {
            var userManager = scope.ServiceProvider.GetRequiredService<UserManager<AppUser>>();
            var user = await userManager.FindByIdAsync(auth.UserId.ToString());
            var added = await userManager.AddToRoleAsync(user!, SystemRoles.SuperAdmin);
            Assert.True(added.Succeeded);
        }

        // Re-login so the JWT carries admin.access.
        return await LoginAsync(email);
    }
}
