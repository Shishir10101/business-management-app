namespace Khata.Infrastructure.Services;

using System.Security.Claims;
using Khata.Application.Interfaces;

/// <summary>
/// Resolves current user information from JWT claims in the HTTP context.
/// </summary>
public class CurrentUserService : ICurrentUserService
{
    public long? UserId { get; private set; }
    public long? BusinessId { get; private set; }
    public string? Email { get; private set; }
    public string? FullName { get; private set; }
    public IReadOnlyList<string> Roles { get; private set; } = [];
    public IReadOnlyList<string> Permissions { get; private set; } = [];
    public bool IsAuthenticated { get; private set; }

    /// <summary>
    /// Factory method: builds CurrentUserService from a ClaimsPrincipal.
    /// </summary>
    public static CurrentUserService FromClaims(ClaimsPrincipal principal)
    {
        var service = new CurrentUserService();

        if (principal.Identity?.IsAuthenticated != true)
            return service;

        service.IsAuthenticated = true;
        service.UserId = GetClaimLong(principal, ClaimTypes.NameIdentifier)
                         ?? GetClaimLong(principal, "sub");
        service.BusinessId = GetClaimLong(principal, "bid");
        service.Email = GetClaim(principal, ClaimTypes.Email)
                        ?? GetClaim(principal, "email");
        service.FullName = GetClaim(principal, "name");
        service.Roles = principal.FindAll(ClaimTypes.Role)
                        .Select(c => c.Value).ToList();
        service.Permissions = principal.FindAll("perms")
                              .Select(c => c.Value).ToList();

        return service;
    }

    public void SetBusinessId(long businessId)
    {
        BusinessId = businessId;
    }

    private static long? GetClaimLong(ClaimsPrincipal principal, string type)
    {
        var value = GetClaim(principal, type);
        return long.TryParse(value, out var result) ? result : null;
    }

    private static string? GetClaim(ClaimsPrincipal principal, string type)
    {
        return principal.FindFirst(type)?.Value;
    }
}
