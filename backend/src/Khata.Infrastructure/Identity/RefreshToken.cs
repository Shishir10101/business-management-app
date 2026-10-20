namespace Khata.Infrastructure.Services;

/// <summary>
/// Refresh token storage entity. Stored as SHA-256 hash in database.
/// Supports token rotation: old tokens are revoked when new ones are issued.
/// </summary>
public class RefreshToken
{
    public long Id { get; set; }
    public long UserId { get; set; }
    public string TokenHash { get; set; } = string.Empty;
    public DateTime ExpiresAt { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? RevokedAt { get; set; }
}
