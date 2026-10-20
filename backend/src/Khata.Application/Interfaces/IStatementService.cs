namespace Khata.Application.Interfaces;

using Khata.Application.DTOs;

/// <summary>
/// Mint and verify HMAC-signed public statement links for customers.
/// No database table — the token carries business, customer and expiry.
/// </summary>
public interface IStatementService
{
    /// <summary>Mint a signed token for a customer's public ledger.</summary>
    /// <param name="customerId">The customer to share.</param>
    /// <param name="ttl">How long the link stays valid. Defaults to 7 days.</param>
    Task<string> MintTokenAsync(long customerId, TimeSpan? ttl = null,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Verify a token and return the ledger. Throws <see cref="UnauthorizedException"/>
    /// if the signature is bad or the token has expired.
    /// </summary>
    Task<PublicStatementDto> GetStatementAsync(string token, int page = 1, int pageSize = 50,
        CancellationToken cancellationToken = default);
}
