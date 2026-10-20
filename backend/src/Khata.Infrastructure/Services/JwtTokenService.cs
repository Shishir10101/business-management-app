namespace Khata.Infrastructure.Services;

using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Khata.Application.Common;
using Khata.Application.Interfaces;
using Khata.Infrastructure.Data;
using Khata.Infrastructure.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;

public class JwtTokenService : ITokenService
{
    private readonly IConfiguration _config;
    private readonly KhataDbContext _db;

    public JwtTokenService(IConfiguration config, KhataDbContext db)
    {
        _config = config;
        _db = db;
    }

    public async Task<(string accessToken, string refreshToken, DateTime expiresAt)> GenerateAccessTokenAsync(
        long userId, string email, string fullName, long? businessId,
        IReadOnlyList<string> roles, IReadOnlyList<string> permissions,
        CancellationToken cancellationToken = default)
    {
        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, userId.ToString()),
            new(JwtRegisteredClaimNames.Email, email),
            new(JwtRegisteredClaimNames.Name, fullName),
            new("bid", businessId?.ToString() ?? "0"),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
        };

        // A null/blank role or permission is data drift, not a reason to fail
        // the whole sign-in (the user would simply be locked out).
        foreach (var role in roles.Where(r => !string.IsNullOrWhiteSpace(r)))
            claims.Add(new Claim(ClaimTypes.Role, role));

        foreach (var perm in permissions.Where(p => !string.IsNullOrWhiteSpace(p)))
            claims.Add(new Claim("perms", perm));

        var key = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(_config["Jwt:Secret"]!));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var expiryMinutes = int.Parse(_config["Jwt:AccessTokenMinutes"] ?? "60");
        var expires = DateTime.UtcNow.AddMinutes(expiryMinutes);

        var token = new JwtSecurityToken(
            issuer: _config["Jwt:Issuer"],
            audience: _config["Jwt:Audience"],
            claims: claims,
            expires: expires,
            signingCredentials: creds);

        var accessToken = new JwtSecurityTokenHandler().WriteToken(token);
        var refreshToken = GenerateRefreshToken();

        // Store refresh token hash in database
        await StoreRefreshTokenAsync(userId, refreshToken, expires, cancellationToken);

        return (accessToken, refreshToken, expires);
    }

    public async Task<RefreshTokenResult> RefreshTokenAsync(
        string refreshToken, CancellationToken cancellationToken = default)
    {
        var hash = HashToken(refreshToken);
        var stored = await _db.Set<RefreshToken>()
            .FirstOrDefaultAsync(rt => rt.TokenHash == hash && rt.RevokedAt == null, cancellationToken);

        if (stored is null || stored.ExpiresAt < DateTime.UtcNow)
            throw new SecurityTokenException("Invalid or expired refresh token.");

        // Revoke old token (rotation)
        stored.RevokedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync(cancellationToken);

        // Get user details
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == stored.UserId, cancellationToken)
            ?? throw new SecurityTokenException("User not found.");

        var businessId = await GetActiveBusinessIdAsync(user.Id, cancellationToken);
        var roles = await GetUserRolesAsync(user.Id, businessId, cancellationToken);
        var perms = await GetUserPermissionsAsync(user.Id, businessId, cancellationToken);

        // Platform roles ride along regardless of business context: a
        // SuperAdmin with no business still gets admin.access, and the
        // tenant filter does not apply to Identity tables.
        var platformPerms = await GetPlatformPermissionsAsync(user.Id, cancellationToken);
        if (platformPerms.Count > 0)
        {
            var merged = perms.ToList();
            merged.AddRange(platformPerms.Where(p => !merged.Contains(p)));
            perms = merged;
        }

        var (accessToken, newRefreshToken, expiresAt) = await GenerateAccessTokenAsync(
            user.Id, user.Email!, user.FullName, businessId,
            roles, perms, cancellationToken);

        return new RefreshTokenResult(
            accessToken, newRefreshToken, expiresAt,
            user.Id, user.Email!, user.FullName, businessId);
    }

    public async Task RevokeRefreshTokenAsync(string refreshToken, CancellationToken cancellationToken = default)
    {
        var hash = HashToken(refreshToken);
        var stored = await _db.Set<RefreshToken>()
            .FirstOrDefaultAsync(rt => rt.TokenHash == hash && rt.RevokedAt == null, cancellationToken);

        if (stored is not null)
        {
            stored.RevokedAt = DateTime.UtcNow;
            await _db.SaveChangesAsync(cancellationToken);
        }
    }

    private async Task StoreRefreshTokenAsync(long userId, string token, DateTime accessExpiry, CancellationToken ct)
    {
        var refreshExpiryDays = int.Parse(_config["Jwt:RefreshTokenDays"] ?? "30");
        var refreshToken = new RefreshToken
        {
            UserId = userId,
            TokenHash = HashToken(token),
            ExpiresAt = DateTime.UtcNow.AddDays(refreshExpiryDays),
            CreatedAt = DateTime.UtcNow
        };

        _db.Set<RefreshToken>().Add(refreshToken);
        await _db.SaveChangesAsync(ct);
    }

    // All membership queries below use IgnoreQueryFilters: they run during login/refresh,
    // where the "current business" claim is absent or stale, which the tenant filter
    // would otherwise translate into an empty result.

    private async Task<IReadOnlyList<string>> GetUserRolesAsync(long userId, long? businessId, CancellationToken ct)
    {
        if (businessId is null) return [];

        var role = await (from bm in _db.BusinessMembers.IgnoreQueryFilters()
                          join r in _db.Roles on bm.RoleId equals r.Id
                          where bm.UserId == userId && bm.BusinessId == businessId
                              && bm.DeletedAt == null && bm.IsActive
                          select r.Name!)
                         .FirstOrDefaultAsync(ct);

        return role is null ? [] : [role];
    }

    private async Task<IReadOnlyList<string>> GetUserPermissionsAsync(long userId, long? businessId, CancellationToken ct)
    {
        if (businessId is null) return [];

        var perms = await (from bm in _db.BusinessMembers.IgnoreQueryFilters()
                           join rp in _db.RolePermissions on bm.RoleId equals rp.RoleId
                           where bm.UserId == userId && bm.BusinessId == businessId
                               && bm.DeletedAt == null && bm.IsActive
                           select rp.Permission.Code)
                          .Distinct()
                          .ToListAsync(ct);
        return perms;
    }

    /// <summary>
    /// Permissions granted through platform-level Identity roles (currently
    /// just SuperAdmin → admin.access). Business membership is irrelevant
    /// here: these roles are assigned directly to the user.
    /// </summary>
    public async Task<IReadOnlyList<string>> GetPlatformPermissionsAsync(
        long userId, CancellationToken cancellationToken = default)
    {
        var platformPerms = await (from ur in _db.UserRoles
                                   join rp in _db.RolePermissions on ur.RoleId equals rp.RoleId
                                   join r in _db.Roles on ur.RoleId equals r.Id
                                   where ur.UserId == userId
                                       && r.Name == SystemRoles.SuperAdmin
                                   select rp.Permission.Code)
                                  .Distinct()
                                  .ToListAsync(cancellationToken);
        return platformPerms;
    }

    private async Task<long?> GetActiveBusinessIdAsync(long userId, CancellationToken ct)
    {
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == userId, ct);
        if (user?.ActiveBusinessId is { } active)
        {
            // Guard against a stale pointer (business deleted / membership revoked).
            var stillMember = await _db.BusinessMembers.IgnoreQueryFilters()
                .AnyAsync(bm => bm.UserId == userId && bm.BusinessId == active
                    && bm.DeletedAt == null && bm.IsActive, ct);
            if (stillMember) return active;
        }

        var firstBusiness = await _db.BusinessMembers.IgnoreQueryFilters()
            .Where(bm => bm.UserId == userId && bm.DeletedAt == null && bm.IsActive)
            .OrderBy(bm => bm.Id)
            .Select(bm => (long?)bm.BusinessId)
            .FirstOrDefaultAsync(ct);

        return firstBusiness;
    }

    private static string GenerateRefreshToken()
    {
        var bytes = RandomNumberGenerator.GetBytes(64);
        return Convert.ToBase64String(bytes);
    }

    private static string HashToken(string token)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(token));
        return Convert.ToHexString(bytes);
    }
}
