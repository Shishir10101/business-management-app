namespace Khata.Admin.Services;

using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using System.Security.Claims;
using System.Text.Json.Serialization;
using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Domain.Enums;
using Microsoft.AspNetCore.Components.Authorization;

/// <summary>
/// Typed client for the platform admin API (<c>/api/admin/*</c>).
///
/// Every call carries the session's bearer token, so the API's admin.access
/// policy is what actually authorizes the work — this class never decides
/// permissions itself. A 401 surfaces as <see cref="AdminApiException"/> with
/// <c>IsUnauthorized</c>, which the UI turns into a redirect to /login.
///
/// Kept free of any Blazor dependency so it is unit-testable with a stub
/// <see cref="HttpMessageHandler"/>.
/// </summary>
public class AdminApiClient
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web)
    {
        Converters = { new JsonStringEnumConverter() },
    };

    /// <summary>Claim carrying the API bearer token inside the auth cookie.</summary>
    public const string TokenClaim = "khata_api_token";

    private readonly HttpClient _http;
    private readonly AuthenticationStateProvider _authState;

    public AdminApiClient(HttpClient http, AuthenticationStateProvider authState)
    {
        _http = http;
        _authState = authState;
    }

    // ---------------------------------------------------------------
    // Auth
    // ---------------------------------------------------------------

    /// <summary>
    /// Validates credentials against the main API and returns the tokens. The
    /// caller (the sign-in endpoint) decides whether to accept them; this
    /// method only proves the credentials.
    /// </summary>
    public async Task<AuthResponse> LoginAsync(
        string email, string password, CancellationToken cancellationToken = default)
    {
        var response = await _http.PostAsJsonAsync(
            "api/auth/login", new { email, password }, JsonOptions, cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            throw new AdminApiException(
                (int)response.StatusCode,
                response.StatusCode == HttpStatusCode.Unauthorized
                    ? "Email or password is incorrect."
                    : $"Login failed ({(int)response.StatusCode}).");
        }

        var auth = await response.Content.ReadFromJsonAsync<AuthResponse>(JsonOptions, cancellationToken)
            ?? throw new AdminApiException(500, "Login returned an empty response.");

        return auth;
    }

    // ---------------------------------------------------------------
    // Statistics
    // ---------------------------------------------------------------

    public Task<PlatformStatsDto> GetStatsAsync(CancellationToken cancellationToken = default)
        => GetAsync<PlatformStatsDto>("api/admin/statistics", cancellationToken);

    // ---------------------------------------------------------------
    // Users
    // ---------------------------------------------------------------

    public Task<PagedResult<AdminUserDto>> GetUsersAsync(
        string? search, bool? isActive, int page, int pageSize,
        CancellationToken cancellationToken = default)
    {
        var url = $"api/admin/users?page={page}&pageSize={pageSize}";
        if (!string.IsNullOrWhiteSpace(search))
            url += $"&search={Uri.EscapeDataString(search)}";
        if (isActive is { } active)
            url += $"&isActive={active.ToString().ToLowerInvariant()}";
        return GetAsync<PagedResult<AdminUserDto>>(url, cancellationToken);
    }

    public Task<AdminUserDto> SuspendUserAsync(
        long userId, string? reason, CancellationToken cancellationToken = default)
        => PostAsync<AdminUserDto>(
            $"api/admin/users/{userId}/suspend", new { reason }, cancellationToken);

    public Task<AdminUserDto> ActivateUserAsync(
        long userId, string? reason, CancellationToken cancellationToken = default)
        => PostAsync<AdminUserDto>(
            $"api/admin/users/{userId}/activate", new { reason }, cancellationToken);

    // ---------------------------------------------------------------
    // Businesses
    // ---------------------------------------------------------------

    public Task<PagedResult<AdminBusinessDto>> GetBusinessesAsync(
        string? search, bool? isActive, int page, int pageSize,
        CancellationToken cancellationToken = default)
    {
        var url = $"api/admin/businesses?page={page}&pageSize={pageSize}";
        if (!string.IsNullOrWhiteSpace(search))
            url += $"&search={Uri.EscapeDataString(search)}";
        if (isActive is { } active)
            url += $"&isActive={active.ToString().ToLowerInvariant()}";
        return GetAsync<PagedResult<AdminBusinessDto>>(url, cancellationToken);
    }

    public Task<AdminBusinessDto> SuspendBusinessAsync(
        long businessId, string? reason, CancellationToken cancellationToken = default)
        => PostAsync<AdminBusinessDto>(
            $"api/admin/businesses/{businessId}/suspend", new { reason }, cancellationToken);

    public Task<AdminBusinessDto> ActivateBusinessAsync(
        long businessId, string? reason, CancellationToken cancellationToken = default)
        => PostAsync<AdminBusinessDto>(
            $"api/admin/businesses/{businessId}/activate", new { reason }, cancellationToken);

    // ---------------------------------------------------------------
    // Audit log
    // ---------------------------------------------------------------

    public Task<PagedResult<AuditLogDto>> GetAuditLogsAsync(
        string? action, int page, int pageSize, CancellationToken cancellationToken = default)
    {
        var url = $"api/admin/audit-logs?page={page}&pageSize={pageSize}";
        if (!string.IsNullOrWhiteSpace(action))
            url += $"&action={Uri.EscapeDataString(action)}";
        return GetAsync<PagedResult<AuditLogDto>>(url, cancellationToken);
    }

    // ---------------------------------------------------------------
    // Feature flags
    // ---------------------------------------------------------------

    public Task<IReadOnlyList<FeatureFlagDto>> GetFeatureFlagsAsync(
        CancellationToken cancellationToken = default)
        => GetAsync<IReadOnlyList<FeatureFlagDto>>("api/admin/feature-flags", cancellationToken);

    public async Task<FeatureFlagDto> SetFeatureFlagAsync(
        string key, bool isEnabled, CancellationToken cancellationToken = default)
    {
        using var request = new HttpRequestMessage(
            HttpMethod.Put, $"api/admin/feature-flags/{Uri.EscapeDataString(key)}")
        {
            Content = JsonContent.Create(new { isEnabled }, options: JsonOptions),
        };
        return await SendAsync<FeatureFlagDto>(request, cancellationToken);
    }

    // ---------------------------------------------------------------
    // Support tickets
    // ---------------------------------------------------------------

    public Task<SupportTicketDto> CreateTicketAsync(
        string subject, string body, long? businessId, SupportTicketPriority priority,
        CancellationToken cancellationToken = default)
        => PostAsync<SupportTicketDto>("api/admin/support-tickets",
            new { subject, body, businessId, priority }, cancellationToken);

    public Task<PagedResult<SupportTicketDto>> GetTicketsAsync(
        SupportTicketStatus? status, int page, int pageSize,
        CancellationToken cancellationToken = default)
    {
        var url = $"api/admin/support-tickets?page={page}&pageSize={pageSize}";
        if (status is { } s)
            url += $"&status={s}";
        return GetAsync<PagedResult<SupportTicketDto>>(url, cancellationToken);
    }

    public async Task<SupportTicketDto> UpdateTicketStatusAsync(
        long ticketId, SupportTicketStatus status, string? resolution,
        CancellationToken cancellationToken = default)
    {
        using var request = new HttpRequestMessage(
            HttpMethod.Put, $"api/admin/support-tickets/{ticketId}/status")
        {
            Content = JsonContent.Create(new { status, resolution }, options: JsonOptions),
        };
        return await SendAsync<SupportTicketDto>(request, cancellationToken);
    }

    // ---------------------------------------------------------------
    // Plumbing
    // ---------------------------------------------------------------

    private async Task<T> GetAsync<T>(string url, CancellationToken cancellationToken)
    {
        using var request = new HttpRequestMessage(HttpMethod.Get, url);
        return await SendAsync<T>(request, cancellationToken);
    }

    private async Task<T> PostAsync<T>(string url, object body, CancellationToken cancellationToken)
    {
        using var request = new HttpRequestMessage(HttpMethod.Post, url)
        {
            Content = JsonContent.Create(body, options: JsonOptions),
        };
        return await SendAsync<T>(request, cancellationToken);
    }

    private async Task<T> SendAsync<T>(HttpRequestMessage request, CancellationToken cancellationToken)
    {
        // The token lives in the auth cookie's claims; Blazor's
        // AuthenticationStateProvider exposes it for the whole circuit, so the
        // client never has to hold mutable auth state of its own.
        var state = await _authState.GetAuthenticationStateAsync();
        var token = state.User.FindFirst(TokenClaim)?.Value;
        if (!string.IsNullOrEmpty(token))
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

        using var response = await _http.SendAsync(request, cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            throw new AdminApiException(
                (int)response.StatusCode, await DescribeAsync(response, cancellationToken));
        }

        var value = await response.Content.ReadFromJsonAsync<T>(JsonOptions, cancellationToken);
        return value ?? throw new AdminApiException(500, "The API returned an empty response.");
    }

    /// <summary>Pulls the ProblemDetails detail out of a failure so the UI can
    /// show what actually went wrong instead of a bare status code.</summary>
    private static async Task<string> DescribeAsync(
        HttpResponseMessage response, CancellationToken cancellationToken)
    {
        try
        {
            var problem = await response.Content.ReadFromJsonAsync<ProblemResponse>(
                JsonOptions, cancellationToken);
            if (!string.IsNullOrWhiteSpace(problem?.Detail))
                return problem!.Detail!;
            if (!string.IsNullOrWhiteSpace(problem?.Title))
                return problem!.Title!;
        }
        catch
        {
            // Not a ProblemDetails body — fall through to the status code.
        }

        return $"Request failed with status {(int)response.StatusCode}.";
    }

    private sealed record ProblemResponse(string? Title, string? Detail, int? Status);
}
