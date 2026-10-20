using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Khata.Infrastructure.Data;
using Khata.Infrastructure.Services;
using Khata.Tests.Testing;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace Khata.Tests.Unit;

/// <summary>
/// Unit tests for JWT access/refresh token generation, rotation, and persistence.
/// </summary>
public class JwtTokenServiceTests : IDisposable
{
    private readonly SqliteConnection _connection;
    private readonly KhataDbContext _db;
    private readonly JwtTokenService _sut;

    public JwtTokenServiceTests()
    {
        _connection = new SqliteConnection("DataSource=:memory:");
        _connection.Open();

        var options = new DbContextOptionsBuilder<KhataDbContext>()
            .UseSqlite(_connection)
            .Options;

        _db = new KhataDbContext(options, new FakeCurrentUserService());
        _db.Database.EnsureCreated();

        // The user that all token tests act on (fixed id 42).
        _db.Users.Add(new Khata.Infrastructure.Identity.AppUser
        {
            Id = 42,
            UserName = "owner@test.local",
            Email = "owner@test.local",
            FullName = "Owner Name",
            IsActive = true,
        });
        _db.SaveChanges();

        var config = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Jwt:Secret"] = "unit-test-secret-key-at-least-32-chars-long!!",
                ["Jwt:Issuer"] = "KhataApi",
                ["Jwt:Audience"] = "KhataMobile",
                ["Jwt:AccessTokenMinutes"] = "60",
                ["Jwt:RefreshTokenDays"] = "30",
            })
            .Build();

        _sut = new JwtTokenService(config, _db);
    }

    [Fact]
    public async Task GenerateAccessTokenAsync_ContainsExpectedClaims()
    {
        var (accessToken, refreshToken, expiresAt) = await _sut.GenerateAccessTokenAsync(
            42, "owner@test.local", "Owner Name", businessId: 7,
            roles: ["Owner"], permissions: ["sales.view", "sales.create"],
            CancellationToken.None);

        Assert.False(string.IsNullOrWhiteSpace(accessToken));
        Assert.False(string.IsNullOrWhiteSpace(refreshToken));
        Assert.True(expiresAt > DateTime.UtcNow);

        var token = new JwtSecurityTokenHandler().ReadJwtToken(accessToken);

        Assert.Equal("42", token.Claims.First(c => c.Type == JwtRegisteredClaimNames.Sub).Value);
        Assert.Equal("owner@test.local", token.Claims.First(c => c.Type == JwtRegisteredClaimNames.Email).Value);
        Assert.Equal("Owner Name", token.Claims.First(c => c.Type == JwtRegisteredClaimNames.Name).Value);
        Assert.Equal("7", token.Claims.First(c => c.Type == "bid").Value);
        Assert.Equal("Owner", token.Claims.First(c => c.Type == ClaimTypes.Role).Value);
        Assert.Contains(token.Claims, c => c.Type == "perms" && c.Value == "sales.view");
        Assert.Contains(token.Claims, c => c.Type == "perms" && c.Value == "sales.create");
        Assert.Equal("KhataApi", token.Issuer);
    }

    [Fact]
    public async Task GenerateAccessTokenAsync_PersistsRefreshTokenHash()
    {
        await _sut.GenerateAccessTokenAsync(
            42, "owner@test.local", "Owner Name", 7, ["Owner"], [], CancellationToken.None);

        var stored = await _db.Set<Khata.Infrastructure.Services.RefreshToken>().ToListAsync();
        Assert.Single(stored);
        Assert.NotEqual(default, stored[0].ExpiresAt);
        Assert.Null(stored[0].RevokedAt);
    }

    [Fact]
    public async Task RefreshTokenAsync_ReturnsUserInfo_AndRotatesToken()
    {
        var (_, refreshToken, _) = await _sut.GenerateAccessTokenAsync(
            42, "owner@test.local", "Owner Name", 7, ["Owner"], ["sales.view"],
            CancellationToken.None);

        var result = await _sut.RefreshTokenAsync(refreshToken, CancellationToken.None);

        Assert.Equal(42, result.UserId);
        Assert.Equal("owner@test.local", result.Email);
        Assert.Equal("Owner Name", result.FullName);
        // User 42 has no business memberships, so the refreshed context has no business.
        Assert.Null(result.BusinessId);
        Assert.NotEqual(refreshToken, result.RefreshToken); // rotation

        var stored = await _db.Set<Khata.Infrastructure.Services.RefreshToken>().ToListAsync();
        Assert.Equal(2, stored.Count);
        Assert.Contains(stored, t => t.RevokedAt != null); // old token revoked
    }

    [Fact]
    public async Task RefreshTokenAsync_WithUnknownToken_ThrowsSecurityTokenException()
    {
        await Assert.ThrowsAsync<Microsoft.IdentityModel.Tokens.SecurityTokenException>(
            () => _sut.RefreshTokenAsync("not-a-real-token", CancellationToken.None));
    }

    [Fact]
    public async Task RevokeRefreshTokenAsync_MarksTokenRevoked()
    {
        var (_, refreshToken, _) = await _sut.GenerateAccessTokenAsync(
            42, "owner@test.local", "Owner Name", 7, ["Owner"], [], CancellationToken.None);

        await _sut.RevokeRefreshTokenAsync(refreshToken, CancellationToken.None);

        var stored = await _db.Set<Khata.Infrastructure.Services.RefreshToken>().SingleAsync();
        Assert.NotNull(stored.RevokedAt);

        // A revoked token can no longer be refreshed.
        await Assert.ThrowsAsync<Microsoft.IdentityModel.Tokens.SecurityTokenException>(
            () => _sut.RefreshTokenAsync(refreshToken, CancellationToken.None));
    }

    public void Dispose()
    {
        _db.Dispose();
        _connection.Dispose();
    }
}
