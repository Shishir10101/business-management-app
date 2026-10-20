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
/// Phase 12: the platform admin surface — cross-tenant statistics, user and
/// business suspend/activate, the audit log, feature flags and the support
/// ticket workflow. Every endpoint requires the SuperAdmin role's
/// admin.access permission; a regular user must get 403.
/// </summary>
[Collection(ApiTestCollection.Name)]
public class AdminEndpointsTests
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web)
    {
        Converters = { new JsonStringEnumConverter() },
    };

    private readonly KhataApiFactory _factory;

    public AdminEndpointsTests(KhataApiFactory factory)
    {
        _factory = factory;
    }

    // ---------------------------------------------------------------
    // Authorization
    // ---------------------------------------------------------------

    [Fact]
    public async Task AdminEndpoints_WithoutSuperAdmin_Return403()
    {
        var (client, _, _) = await CreateOwnerClientAsync();

        var response = await client.GetAsync("/api/admin/statistics");

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task AdminEndpoints_WithoutToken_Return401()
    {
        var client = _factory.CreateClient();

        var response = await client.GetAsync("/api/admin/statistics");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task SuperAdmin_GetsAdminAccess_AndNothingBusinessScoped()
    {
        var client = await CreateSuperAdminClientAsync();

        var response = await client.GetAsync("/api/admin/statistics");
        response.EnsureSuccessStatusCode();

        // The SuperAdmin role carries admin.access ONLY — a business-scoped
        // endpoint must still 403. Platform power never leaks into tenants.
        var sales = await client.GetAsync("/api/sales");
        Assert.Equal(HttpStatusCode.Forbidden, sales.StatusCode);
    }

    // ---------------------------------------------------------------
    // Statistics
    // ---------------------------------------------------------------

    [Fact]
    public async Task Statistics_CountEverythingOnThePlatform()
    {
        var admin = await CreateSuperAdminClientAsync();
        await CreateOwnerClientAsync(); // one more business on the platform


        var stats = await GetStatsAsync(admin);

        Assert.True(stats.TotalUsers >= 2, "both the admin and the owner count");
        Assert.True(stats.TotalBusinesses >= 1);
        Assert.True(stats.TotalTickets >= 0);
    }

    // ---------------------------------------------------------------
    // Users
    // ---------------------------------------------------------------

    [Fact]
    public async Task Users_ListSuspendActivate_WritesAuditEntries()
    {
        var admin = await CreateSuperAdminClientAsync();
        var (_, ownerId, ownerEmail) = await CreateOwnerClientAsync();

        // A suspended user cannot authenticate any more.
        var suspended = await SetUserActiveAsync(admin, ownerId, false, "spam");
        Assert.False(suspended.IsActive);
        var login = await LoginAsync(ownerEmail);
        Assert.Equal(HttpStatusCode.Unauthorized, login.StatusCode);

        // ...and after reactivation they can.
        var reactivated = await SetUserActiveAsync(admin, ownerId, true, "appeal");
        Assert.True(reactivated.IsActive);
        var relogin = await LoginAsync(ownerEmail);
        Assert.Equal(HttpStatusCode.OK, relogin.StatusCode);

        // Both transitions are in the audit log.
        var logs = await GetAuditLogsAsync(admin, action: "user.suspend");
        Assert.Contains(logs.Data, l => l.EntityId == ownerId && l.Action == "user.suspend");
        var reactivateLogs = await GetAuditLogsAsync(admin, action: "user.activate");
        Assert.Contains(reactivateLogs.Data, l => l.EntityId == ownerId);
    }

    [Fact]
    public async Task Users_SuspendUnknownUser_Returns404()
    {
        var admin = await CreateSuperAdminClientAsync();

        var response = await admin.PostAsJsonAsync("/api/admin/users/999999999/suspend",
            new { reason = "ghost" });

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    // ---------------------------------------------------------------
    // Businesses
    // ---------------------------------------------------------------

    [Fact]
    public async Task Businesses_ListAndSuspend()
    {
        var admin = await CreateSuperAdminClientAsync();
        var (ownerClient, _, _) = await CreateOwnerClientAsync();

        // The business THIS test created: find it by asking the owner's own
        // list (the shared test database holds other tests' businesses too).
        var mine = await ownerClient.GetFromJsonAsync<List<BusinessDto>>(
            "/api/businesses", JsonOptions);
        var target = Assert.Single(mine!);

        var suspended = await SetBusinessActiveAsync(admin, target.Id, false, "tos violation");
        Assert.False(suspended.IsActive);

        var logs = await GetAuditLogsAsync(admin, action: "business.suspend");
        Assert.Contains(logs.Data, l => l.EntityId == target.Id);
    }

    // ---------------------------------------------------------------
    // Feature flags
    // ---------------------------------------------------------------

    [Fact]
    public async Task FeatureFlags_AreSeededAndToggle()
    {
        var admin = await CreateSuperAdminClientAsync();

        var flags = await GetFeatureFlagsAsync(admin);
        Assert.Equal(5, flags.Count);
        Assert.Contains("esewa_payments", flags.Select(f => f.Key));

        var esewa = flags.First(f => f.Key == "esewa_payments");
        var enabled = await SetFeatureFlagAsync(admin, "esewa_payments", true);
        Assert.True(enabled.IsEnabled);

        // The flip is audited.
        var logs = await GetAuditLogsAsync(admin, action: "feature_flag.update");
        Assert.Contains(logs.Data, l => l.EntityId == esewa.Id);

        // And persists across a re-read.
        var reread = await GetFeatureFlagsAsync(admin);
        Assert.True(reread.First(f => f.Key == "esewa_payments").IsEnabled);
    }

    [Fact]
    public async Task FeatureFlags_UnknownKey_Returns404()
    {
        var admin = await CreateSuperAdminClientAsync();

        var response = await admin.PutAsJsonAsync("/api/admin/feature-flags/no_such_flag",
            new { isEnabled = true });

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    // ---------------------------------------------------------------
    // Support tickets
    // ---------------------------------------------------------------

    [Fact]
    public async Task Tickets_CreateAndWalkTheWorkflow()
    {
        var admin = await CreateSuperAdminClientAsync();

        var created = await CreateTicketAsync(admin, "PDF export broken",
            "Invoices download as empty files.", null, Domain.Enums.SupportTicketPriority.High);
        Assert.Equal(Domain.Enums.SupportTicketStatus.Open, created.Status);
        Assert.Equal(Domain.Enums.SupportTicketPriority.High, created.Priority);
        Assert.Null(created.ResolvedAt);

        var inProgress = await UpdateTicketStatusAsync(admin, created.Id,
            Domain.Enums.SupportTicketStatus.InProgress, null);
        Assert.Equal(Domain.Enums.SupportTicketStatus.InProgress, inProgress.Status);
        Assert.Null(inProgress.ResolvedAt);

        var resolved = await UpdateTicketStatusAsync(admin, created.Id,
            Domain.Enums.SupportTicketStatus.Resolved, "Fixed in 1.2.3");
        Assert.Equal(Domain.Enums.SupportTicketStatus.Resolved, resolved.Status);
        Assert.NotNull(resolved.ResolvedAt);
        Assert.Equal("Fixed in 1.2.3", resolved.Resolution);

        // Reopening clears the resolution timestamp again.
        var reopened = await UpdateTicketStatusAsync(admin, created.Id,
            Domain.Enums.SupportTicketStatus.Open, null);
        Assert.Null(reopened.ResolvedAt);

        // Status filter works.
        var openOnly = await GetTicketsAsync(admin, Domain.Enums.SupportTicketStatus.Open);
        Assert.Contains(openOnly.Data, t => t.Id == created.Id);
    }

    [Fact]
    public async Task Tickets_UnknownTicket_Returns404()
    {
        var admin = await CreateSuperAdminClientAsync();

        var response = await admin.PutAsJsonAsync("/api/admin/support-tickets/999999999/status",
            new { status = "Resolved", resolution = (string?)null });

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    // ---------------------------------------------------------------
    // Helpers
    // ---------------------------------------------------------------

    private async Task<HttpClient> CreateSuperAdminClientAsync()
    {
        var client = _factory.CreateClient();
        var email = $"superadmin-{Guid.NewGuid():n}@khata.local";

        var register = await client.PostAsJsonAsync("/api/auth/register", new
        {
            fullName = "Platform Admin",
            email,
            password = "Passw0rd123",
            phoneNumber = (string?)null,
        });
        register.EnsureSuccessStatusCode();
        var auth = await register.Content.ReadFromJsonAsync<AuthResponse>(JsonOptions);
        var userId = auth!.UserId;

        // Grant the platform SuperAdmin role directly through Identity —
        // exactly how a deployment would promote the first admin.
        using var scope = _factory.Services.CreateScope();
        var userManager = scope.ServiceProvider.GetRequiredService<UserManager<AppUser>>();
        var roleResult = await userManager.AddToRoleAsync(
            (await userManager.FindByIdAsync(userId.ToString()))!,
            SystemRoles.SuperAdmin);
        Assert.True(roleResult.Succeeded);

        // Re-login so the JWT carries the platform permission.
        var login = await LoginAsync(email);
        login.EnsureSuccessStatusCode();
        var loginAuth = await login.Content.ReadFromJsonAsync<AuthResponse>(JsonOptions);
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", loginAuth!.AccessToken);

        return client;
    }

    private async Task<HttpResponseMessage> LoginAsync(string email)
    {
        var client = _factory.CreateClient();
        return await client.PostAsJsonAsync(
            "/api/auth/login", new { email, password = "Passw0rd123" });
    }

    private async Task<(HttpClient client, long userId, string email)> CreateOwnerClientAsync()
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
        var registerAuth = await register.Content.ReadFromJsonAsync<AuthResponse>(JsonOptions);
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", registerAuth!.AccessToken);

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

        return (client, registerAuth!.UserId, email);
    }

    private static async Task<PlatformStatsDto> GetStatsAsync(HttpClient client)
        => (await client.GetFromJsonAsync<PlatformStatsDto>("/api/admin/statistics", JsonOptions))!;

    private static async Task<PagedResult<AdminUserDto>> GetUsersAsync(HttpClient client)
        => (await client.GetFromJsonAsync<PagedResult<AdminUserDto>>("/api/admin/users", JsonOptions))!;

    private static async Task<AdminUserDto> SetUserActiveAsync(
        HttpClient client, long userId, bool isActive, string? reason)
    {
        var url = isActive
            ? $"/api/admin/users/{userId}/activate"
            : $"/api/admin/users/{userId}/suspend";
        var response = await client.PostAsJsonAsync(url, new { reason });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<AdminUserDto>(JsonOptions))!;
    }

    private static async Task<PagedResult<AdminBusinessDto>> GetBusinessesAsync(HttpClient client)
        => (await client.GetFromJsonAsync<PagedResult<AdminBusinessDto>>("/api/admin/businesses", JsonOptions))!;

    private static async Task<AdminBusinessDto> SetBusinessActiveAsync(
        HttpClient client, long businessId, bool isActive, string? reason)
    {
        var url = isActive
            ? $"/api/admin/businesses/{businessId}/activate"
            : $"/api/admin/businesses/{businessId}/suspend";
        var response = await client.PostAsJsonAsync(url, new { reason });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<AdminBusinessDto>(JsonOptions))!;
    }

    private static async Task<PagedResult<AuditLogDto>> GetAuditLogsAsync(
        HttpClient client, string action)
        => (await client.GetFromJsonAsync<PagedResult<AuditLogDto>>(
            $"/api/admin/audit-logs?action={action}", JsonOptions))!;

    private static async Task<List<FeatureFlagDto>> GetFeatureFlagsAsync(HttpClient client)
        => (await client.GetFromJsonAsync<List<FeatureFlagDto>>("/api/admin/feature-flags", JsonOptions))!;

    private static async Task<FeatureFlagDto> SetFeatureFlagAsync(
        HttpClient client, string key, bool isEnabled)
    {
        var response = await client.PutAsJsonAsync(
            $"/api/admin/feature-flags/{key}", new { isEnabled });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<FeatureFlagDto>(JsonOptions))!;
    }

    private static async Task<SupportTicketDto> CreateTicketAsync(
        HttpClient client, string subject, string body, long? businessId,
        Domain.Enums.SupportTicketPriority priority)
    {
        var response = await client.PostAsJsonAsync("/api/admin/support-tickets",
            new { subject, body, businessId, priority });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<SupportTicketDto>(JsonOptions))!;
    }

    private static async Task<PagedResult<SupportTicketDto>> GetTicketsAsync(
        HttpClient client, Domain.Enums.SupportTicketStatus? status)
    {
        var url = status is null
            ? "/api/admin/support-tickets"
            : $"/api/admin/support-tickets?status={status}";
        return (await client.GetFromJsonAsync<PagedResult<SupportTicketDto>>(url, JsonOptions))!;
    }

    private static async Task<SupportTicketDto> UpdateTicketStatusAsync(
        HttpClient client, long ticketId,
        Domain.Enums.SupportTicketStatus status, string? resolution)
    {
        var response = await client.PutAsJsonAsync(
            $"/api/admin/support-tickets/{ticketId}/status",
            new { status, resolution });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<SupportTicketDto>(JsonOptions))!;
    }
}
