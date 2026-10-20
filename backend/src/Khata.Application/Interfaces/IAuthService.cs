namespace Khata.Application.Interfaces;

/// <summary>
/// Result of a refresh-token exchange: new token pair plus the identity
/// claims needed to rebuild the full AuthResponse.
/// </summary>
public record RefreshTokenResult(
    string AccessToken,
    string RefreshToken,
    DateTime ExpiresAt,
    long UserId,
    string Email,
    string FullName,
    long? BusinessId
);

/// <summary>
/// JWT token generation and validation service.
/// </summary>
public interface ITokenService
{
    Task<(string accessToken, string refreshToken, DateTime expiresAt)> GenerateAccessTokenAsync(
        long userId, string email, string fullName, long? businessId,
        IReadOnlyList<string> roles, IReadOnlyList<string> permissions,
        CancellationToken cancellationToken = default);

    Task<RefreshTokenResult> RefreshTokenAsync(
        string refreshToken, CancellationToken cancellationToken = default);

    /// <summary>
    /// Platform-role permissions for a user (the SuperAdmin's admin.access),
    /// merged into the JWT in addition to the active business's permissions.
    /// Empty for users with no platform role.
    /// </summary>
    Task<IReadOnlyList<string>> GetPlatformPermissionsAsync(
        long userId, CancellationToken cancellationToken = default);

    Task RevokeRefreshTokenAsync(string refreshToken, CancellationToken cancellationToken = default);
}

/// <summary>
/// Repository for user authentication operations.
/// </summary>
public interface IAuthRepository
{
    Task<bool> EmailExistsAsync(string email, CancellationToken cancellationToken = default);
    Task<long> CreateUserAsync(string email, string fullName, string passwordHash,
        string? phoneNumber, string locale, CancellationToken cancellationToken = default);
    Task<(long userId, string fullName, string email, string? passwordHash, bool isActive,
        long? activeBusinessId, string? locale)?>
        GetUserByEmailAsync(string email, CancellationToken cancellationToken = default);
    Task<bool> VerifyPasswordAsync(string email, string password, CancellationToken cancellationToken = default);
    Task UpdateUserLoginAsync(long userId, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<(long businessId, string businessName, string roleName)>>
        GetUserBusinessesAsync(long userId, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<string>> GetBusinessPermissionsAsync(long userId, long businessId,
        CancellationToken cancellationToken = default);
    Task<(string fullName, string? phoneNumber, string locale, string timezone, string? profileImageUrl)>
        GetUserProfileAsync(long userId, CancellationToken cancellationToken = default);
    Task UpdateUserProfileAsync(long userId, string fullName, string? phoneNumber,
        string locale, CancellationToken cancellationToken = default);
    Task<bool> ChangePasswordAsync(long userId, string currentPassword, string newPassword,
        CancellationToken cancellationToken = default);
    Task SetActiveBusinessAsync(long userId, long businessId, CancellationToken cancellationToken = default);
}
