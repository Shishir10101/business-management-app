using System.Net;
using System.Net.Http.Headers;
using System.Security.Claims;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using Khata.Admin.Services;
using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Domain.Enums;
using Microsoft.AspNetCore.Components.Authorization;
using Xunit;

namespace Khata.Tests.Unit;

/// <summary>
/// The admin console's API client: token attachment, URL/body shapes, DTO
/// parsing and error surfacing. Uses a stub handler so the tests pin the
/// client's contract with the API without booting either app.
/// </summary>
public class AdminApiClientTests
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web)
    {
        Converters = { new JsonStringEnumConverter() },
    };

    private static (AdminApiClient client, FakeAuthStateProvider authState, StubHandler handler)
        CreateClient(bool authenticated = true)
    {
        var handler = new StubHandler();
        var http = new HttpClient(handler) { BaseAddress = new Uri("http://api.test/") };
        var authState = new FakeAuthStateProvider(
            authenticated
                ? new ClaimsPrincipal(new ClaimsIdentity(
                    [
                        new Claim(ClaimTypes.NameIdentifier, "42"),
                        new Claim(ClaimTypes.Email, "admin@khata.local"),
                        new Claim(ClaimTypes.Name, "Platform Admin"),
                        new Claim(AdminApiClient.TokenClaim, "test-token"),
                    ], "AdminCookie"))
                : new ClaimsPrincipal(new ClaimsIdentity()));

        return (new AdminApiClient(http, authState), authState, handler);
    }

    // ---------------------------------------------------------------
    // Auth
    // ---------------------------------------------------------------

    [Fact]
    public async Task Login_SendsCredentials_AndParsesAuthResponse()
    {
        var (client, _, handler) = CreateClient(authenticated: false);
        handler.Respond(HttpStatusCode.OK, """
            {
              "userId": 7,
              "email": "admin@khata.local",
              "fullName": "Platform Admin",
              "accessToken": "jwt-token",
              "refreshToken": "refresh",
              "expiresIn": 3600,
              "businesses": null
            }
            """);

        var auth = await client.LoginAsync("admin@khata.local", "Passw0rd123");

        Assert.Equal(7, auth.UserId);
        Assert.Equal("jwt-token", auth.AccessToken);

        var request = Assert.Single(handler.Requests);
        Assert.Equal(HttpMethod.Post, request.Method);
        Assert.Equal("http://api.test/api/auth/login", request.Uri);
        Assert.Contains("\"email\":\"admin@khata.local\"", request.Body);
        // Login is the one call made WITHOUT a token.
        Assert.Null(request.Authorization);
    }

    [Fact]
    public async Task Login_WithBadCredentials_ThrowsUnauthorizedWithFriendlyMessage()
    {
        var (client, _, handler) = CreateClient(authenticated: false);
        handler.Respond(HttpStatusCode.Unauthorized, """
            {"title":"Invalid credentials","status":401,"detail":"Email or password is incorrect."}
            """);

        var ex = await Assert.ThrowsAsync<AdminApiException>(
            () => client.LoginAsync("admin@khata.local", "wrong"));

        Assert.True(ex.IsUnauthorized);
        Assert.Equal("Email or password is incorrect.", ex.Message);
    }

    // ---------------------------------------------------------------
    // Token attachment
    // ---------------------------------------------------------------

    [Fact]
    public async Task AuthenticatedCalls_CarryTheBearerToken()
    {
        var (client, _, handler) = CreateClient();
        handler.Respond(HttpStatusCode.OK, """
            {"totalUsers":1,"activeUsers":1,"totalBusinesses":2,"activeBusinesses":2,
             "totalSales":3,"totalSalesPaisa":300,"totalPayments":1,
             "totalPaymentsPaisa":100,"openTickets":0,"totalTickets":0}
            """);

        await client.GetStatsAsync();

        var request = Assert.Single(handler.Requests);
        Assert.Equal("Bearer", request.Authorization?.Scheme);
        Assert.Equal("test-token", request.Authorization?.Parameter);
    }

    // ---------------------------------------------------------------
    // Statistics
    // ---------------------------------------------------------------

    [Fact]
    public async Task GetStats_ParsesThePlatformTotals()
    {
        var (client, _, handler) = CreateClient();
        handler.Respond(HttpStatusCode.OK, """
            {"totalUsers":120,"activeUsers":115,"totalBusinesses":48,"activeBusinesses":44,
             "totalSales":910,"totalSalesPaisa":12345600,"totalPayments":300,
             "totalPaymentsPaisa":5000000,"openTickets":3,"totalTickets":9}
            """);

        var stats = await client.GetStatsAsync();

        Assert.Equal(120, stats.TotalUsers);
        Assert.Equal(48, stats.TotalBusinesses);
        Assert.Equal(12_345_600, stats.TotalSalesPaisa);
        Assert.Equal(3, stats.OpenTickets);
        Assert.Equal("http://api.test/api/admin/statistics", handler.Requests[0].Uri);
    }

    // ---------------------------------------------------------------
    // Users
    // ---------------------------------------------------------------

    [Fact]
    public async Task GetUsers_BuildsTheQueryStringFromFilters()
    {
        var (client, _, handler) = CreateClient();
        handler.Respond(HttpStatusCode.OK, """
            {"data":[],"pagination":{"page":2,"pageSize":20,"totalItems":0,"totalPages":0,
             "hasNext":false,"hasPrev":true}}
            """);

        await client.GetUsersAsync("ram kumar", isActive: false, page: 2, pageSize: 20);

        var uri = handler.Requests[0].Uri;
        Assert.Contains("/api/admin/users?", uri);
        Assert.Contains("page=2", uri);
        Assert.Contains("pageSize=20", uri);
        // Search terms must be URL-encoded (a raw space breaks the request).
        Assert.Contains("search=ram%20kumar", uri);
        Assert.Contains("isActive=false", uri);
    }

    [Fact]
    public async Task GetUsers_OmitsAbsentFilters()
    {
        var (client, _, handler) = CreateClient();
        handler.Respond(HttpStatusCode.OK, """
            {"data":[],"pagination":{"page":1,"pageSize":20,"totalItems":0,"totalPages":0,
             "hasNext":false,"hasPrev":false}}
            """);

        await client.GetUsersAsync(null, null, 1, 20);

        var uri = handler.Requests[0].Uri;
        Assert.DoesNotContain("search=", uri);
        Assert.DoesNotContain("isActive=", uri);
    }

    [Fact]
    public async Task SuspendUser_PostsTheReason()
    {
        var (client, _, handler) = CreateClient();
        handler.Respond(HttpStatusCode.OK, """
            {"id":9,"email":"spam@khata.local","fullName":"Spam","isActive":false,
             "locale":"ne","createdAt":"2026-10-16T00:00:00Z","businessCount":0}
            """);

        var user = await client.SuspendUserAsync(9, "spam");

        Assert.False(user.IsActive);
        var request = Assert.Single(handler.Requests);
        Assert.Equal(HttpMethod.Post, request.Method);
        Assert.Equal("http://api.test/api/admin/users/9/suspend", request.Uri);
        Assert.Contains("\"reason\":\"spam\"", request.Body);
    }

    [Fact]
    public async Task ActivateUser_UsesTheActivateRoute()
    {
        var (client, _, handler) = CreateClient();
        handler.Respond(HttpStatusCode.OK, """
            {"id":9,"email":"a@khata.local","fullName":"A","isActive":true,
             "locale":"ne","createdAt":"2026-10-16T00:00:00Z","businessCount":1}
            """);

        await client.ActivateUserAsync(9, null);

        Assert.Equal("http://api.test/api/admin/users/9/activate", handler.Requests[0].Uri);
    }

    // ---------------------------------------------------------------
    // Businesses
    // ---------------------------------------------------------------

    [Fact]
    public async Task SuspendBusiness_HitsTheBusinessRoute()
    {
        var (client, _, handler) = CreateClient();
        handler.Respond(HttpStatusCode.OK, """
            {"id":3,"name":"Shop","type":"Retail","province":3,"isActive":false,
             "createdAt":"2026-10-16T00:00:00Z","memberCount":2,"saleCount":10}
            """);

        var business = await client.SuspendBusinessAsync(3, "tos");

        Assert.False(business.IsActive);
        Assert.Equal("http://api.test/api/admin/businesses/3/suspend", handler.Requests[0].Uri);
    }

    // ---------------------------------------------------------------
    // Feature flags
    // ---------------------------------------------------------------

    [Fact]
    public async Task SetFeatureFlag_SendsAPutWithTheNewState()
    {
        var (client, _, handler) = CreateClient();
        handler.Respond(HttpStatusCode.OK, """
            {"id":1,"key":"esewa_payments","isEnabled":true,"description":"eSewa"}
            """);

        var flag = await client.SetFeatureFlagAsync("esewa_payments", true);

        Assert.True(flag.IsEnabled);
        var request = Assert.Single(handler.Requests);
        Assert.Equal(HttpMethod.Put, request.Method);
        Assert.Equal("http://api.test/api/admin/feature-flags/esewa_payments", request.Uri);
        Assert.Contains("\"isEnabled\":true", request.Body);
    }

    [Fact]
    public async Task GetFeatureFlags_ParsesTheList()
    {
        var (client, _, handler) = CreateClient();
        handler.Respond(HttpStatusCode.OK, """
            [{"id":1,"key":"esewa_payments","isEnabled":false,"description":"eSewa"},
             {"id":2,"key":"khalti_payments","isEnabled":true,"description":"Khalti"}]
            """);

        var flags = await client.GetFeatureFlagsAsync();

        Assert.Equal(2, flags.Count);
        Assert.Equal("khalti_payments", flags[1].Key);
        Assert.True(flags[1].IsEnabled);
    }

    // ---------------------------------------------------------------
    // Support tickets
    // ---------------------------------------------------------------

    [Fact]
    public async Task UpdateTicketStatus_SendsStatusAndResolution()
    {
        var (client, _, handler) = CreateClient();
        handler.Respond(HttpStatusCode.OK, """
            {"id":5,"subject":"PDF broken","body":"details","status":"Resolved",
             "priority":"High","reportedByUserId":42,"businessId":null,
             "assignedToUserId":null,"resolution":"Fixed in 1.2.3",
             "resolvedAt":"2026-10-16T10:00:00Z","createdAt":"2026-10-16T09:00:00Z"}
            """);

        var ticket = await client.UpdateTicketStatusAsync(
            5, SupportTicketStatus.Resolved, "Fixed in 1.2.3");

        Assert.Equal(SupportTicketStatus.Resolved, ticket.Status);
        Assert.Equal("Fixed in 1.2.3", ticket.Resolution);

        var request = Assert.Single(handler.Requests);
        Assert.Equal(HttpMethod.Put, request.Method);
        Assert.Equal("http://api.test/api/admin/support-tickets/5/status", request.Uri);
        Assert.Contains("\"status\":\"Resolved\"", request.Body);
        Assert.Contains("\"resolution\":\"Fixed in 1.2.3\"", request.Body);
    }

    [Fact]
    public async Task GetTickets_EncodesTheStatusFilter()
    {
        var (client, _, handler) = CreateClient();
        handler.Respond(HttpStatusCode.OK, """
            {"data":[],"pagination":{"page":1,"pageSize":20,"totalItems":0,"totalPages":0,
             "hasNext":false,"hasPrev":false}}
            """);

        await client.GetTicketsAsync(SupportTicketStatus.InProgress, 1, 20);

        Assert.Contains("status=InProgress", handler.Requests[0].Uri);
    }

    // ---------------------------------------------------------------
    // Error surfacing
    // ---------------------------------------------------------------

    [Fact]
    public async Task NotFound_SurfacesTheProblemDetailsMessage()
    {
        var (client, _, handler) = CreateClient();
        handler.Respond(HttpStatusCode.NotFound, """
            {"title":"Not found","status":404,"detail":"FeatureFlag with key 'nope' was not found."}
            """);

        var ex = await Assert.ThrowsAsync<AdminApiException>(
            () => client.SetFeatureFlagAsync("nope", true));

        Assert.True(ex.IsNotFound);
        Assert.Contains("was not found", ex.Message);
    }

    [Fact]
    public async Task Forbidden_IsDistinguishableFromUnauthorized()
    {
        var (client, _, handler) = CreateClient();
        handler.Respond(HttpStatusCode.Forbidden, """
            {"title":"Forbidden","status":403}
            """);

        var ex = await Assert.ThrowsAsync<AdminApiException>(() => client.GetStatsAsync());

        Assert.True(ex.IsForbidden);
        Assert.False(ex.IsUnauthorized);
    }

    [Fact]
    public async Task Unauthorized_IsFlaggedSoTheUiCanRedirect()
    {
        var (client, _, handler) = CreateClient();
        handler.Respond(HttpStatusCode.Unauthorized, "{}");

        var ex = await Assert.ThrowsAsync<AdminApiException>(() => client.GetStatsAsync());

        Assert.True(ex.IsUnauthorized);
    }

    [Fact]
    public async Task FailureWithoutProblemDetails_StillReportsTheStatusCode()
    {
        var (client, _, handler) = CreateClient();
        handler.Respond(HttpStatusCode.InternalServerError, "not json at all");

        var ex = await Assert.ThrowsAsync<AdminApiException>(() => client.GetStatsAsync());

        Assert.Equal(500, ex.StatusCode);
        Assert.Contains("500", ex.Message);
    }

    // ---------------------------------------------------------------
    // Anonymous access
    // ---------------------------------------------------------------

    [Fact]
    public async Task AnonymousCall_OmitsTheAuthorizationHeader()
    {
        var (client, _, handler) = CreateClient(authenticated: false);
        handler.Respond(HttpStatusCode.Unauthorized, "{}");

        await Assert.ThrowsAsync<AdminApiException>(() => client.GetStatsAsync());

        Assert.Null(Assert.Single(handler.Requests).Authorization);
    }

    // ---------------------------------------------------------------
    // Stub transport
    // ---------------------------------------------------------------

    private sealed record RecordedRequest(
        HttpMethod Method, string Uri, string? Body, AuthenticationHeaderValue? Authorization);

    /// <summary>Stands in for Blazor's AuthenticationStateProvider, which is
    /// what supplies the bearer token in the real app.</summary>
    private sealed class FakeAuthStateProvider : AuthenticationStateProvider
    {
        private readonly ClaimsPrincipal _user;

        public FakeAuthStateProvider(ClaimsPrincipal user) => _user = user;

        public override Task<AuthenticationState> GetAuthenticationStateAsync()
            => Task.FromResult(new AuthenticationState(_user));
    }

    private sealed class StubHandler : HttpMessageHandler
    {
        private HttpStatusCode _status = HttpStatusCode.OK;
        private string _body = "{}";

        public List<RecordedRequest> Requests { get; } = [];

        public void Respond(HttpStatusCode status, string body)
        {
            _status = status;
            _body = body;
        }

        protected override async Task<HttpResponseMessage> SendAsync(
            HttpRequestMessage request, CancellationToken cancellationToken)
        {
            var body = request.Content is null
                ? null
                : await request.Content.ReadAsStringAsync(cancellationToken);

            // OriginalString, not ToString(): the latter decodes percent
            // escapes, which would hide whether the client encoded its query.
            Requests.Add(new RecordedRequest(
                request.Method,
                request.RequestUri?.OriginalString ?? string.Empty,
                body,
                request.Headers.Authorization));

            return new HttpResponseMessage(_status)
            {
                Content = new StringContent(_body, Encoding.UTF8, "application/json"),
            };
        }
    }
}
