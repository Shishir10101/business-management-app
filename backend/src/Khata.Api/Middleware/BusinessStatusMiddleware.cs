namespace Khata.Api.Middleware;

using System.Security.Claims;
using Khata.Application.Common;
using Khata.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;

/// <summary>
/// Refuses requests whose JWT belongs to a suspended account or a suspended
/// business.
/// </summary>
/// <remarks>
/// <para>
/// A JWT is a bearer credential the API cannot un-issue. The admin console can
/// suspend a user or a business, but without a check on every request that
/// suspension only takes effect when the current access token expires — and
/// before this middleware the refresh path did not check either, so a suspended
/// shop kept working indefinitely.
/// </para>
/// <para>
/// Both lookups are cached for a few seconds per id so ordinary traffic does
/// not pay two queries on every request. Set <c>BusinessStatus:CacheSeconds</c>
/// to 0 to disable caching (the test suite does, so a suspension is visible on
/// the next request).
/// </para>
/// </remarks>
public sealed class BusinessStatusMiddleware
{
    private readonly RequestDelegate _next;
    private readonly IMemoryCache _cache;
    private readonly int _cacheSeconds;

    public BusinessStatusMiddleware(
        RequestDelegate next,
        IMemoryCache cache,
        IConfiguration configuration,
        IHostEnvironment environment)
    {
        _next = next;
        _cache = cache;
        // The test suite asserts the next request after a suspension, so it
        // must never read a cached "active" answer.
        _cacheSeconds = environment.IsEnvironment("Testing")
            ? 0
            : configuration.GetValue("BusinessStatus:CacheSeconds", 30);
    }

    public async Task InvokeAsync(HttpContext context, KhataDbContext db)
    {
        if (context.User.Identity?.IsAuthenticated == true && !IsExempt(context.Request.Path))
        {
            if (TryGetId(context.User, ClaimTypes.NameIdentifier, "sub", out var userId) &&
                !await IsCachedAsync(CacheKeys.UserActive(userId), () =>
                    db.Users.AnyAsync(u => u.Id == userId && u.IsActive, context.RequestAborted)))
            {
                await RefuseAsync(context, StatusCodes.Status401Unauthorized,
                    "Account suspended", "This account is not active. Contact support.");
                return;
            }

            if (TryGetId(context.User, "bid", null, out var businessId) && businessId > 0 &&
                !await IsCachedAsync(CacheKeys.BusinessActive(businessId), () =>
                    db.Businesses.IgnoreQueryFilters()
                        .AnyAsync(b => b.Id == businessId && b.IsActive && b.DeletedAt == null,
                            context.RequestAborted)))
            {
                await RefuseAsync(context, StatusCodes.Status403Forbidden,
                    "Business suspended", "This business is not active. Contact support.");
                return;
            }
        }

        await _next(context);
    }

    private static bool IsExempt(PathString path) =>
        // The three anonymous auth endpoints. /api/auth/me and change-password
        // are NOT exempt: a suspended user must not keep using them.
        path.StartsWithSegments("/api/auth/login") ||
        path.StartsWithSegments("/api/auth/register") ||
        path.StartsWithSegments("/api/auth/refresh") ||
        path.StartsWithSegments("/health") ||
        path.StartsWithSegments("/s") ||
        path.StartsWithSegments("/openapi") ||
        // Recovery path: a user whose active business was suspended or deleted
        // must still be able to list, create and switch businesses. Without
        // this the client is locked out of the very screen that fixes it.
        path.StartsWithSegments("/api/businesses");

    private static bool TryGetId(ClaimsPrincipal user, string primary, string? fallback, out long id)
    {
        id = 0;
        var raw = user.FindFirstValue(primary) ?? (fallback is null ? null : user.FindFirstValue(fallback));
        return long.TryParse(raw, out id);
    }

    private async Task<bool> IsCachedAsync(string key, Func<Task<bool>> query)
    {
        if (_cacheSeconds <= 0)
            return await query();

        if (_cache.TryGetValue(key, out bool cached))
            return cached;

        var active = await query();
        _cache.Set(key, active, TimeSpan.FromSeconds(_cacheSeconds));
        return active;
    }

    private static Task RefuseAsync(HttpContext context, int status, string title, string detail)
    {
        context.Response.StatusCode = status;
        return context.Response.WriteAsJsonAsync(new
        {
            type = $"https://httpstatuses.io/{status}",
            title,
            status,
            detail,
            traceId = context.TraceIdentifier,
        });
    }
}
