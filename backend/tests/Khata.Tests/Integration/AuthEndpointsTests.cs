using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Khata.Application.DTOs;
using Khata.Tests.Testing;
using Xunit;

namespace Khata.Tests.Integration;

[Collection(ApiTestCollection.Name)]
public class AuthEndpointsTests
{
    private readonly KhataApiFactory _factory;

    public AuthEndpointsTests(KhataApiFactory factory)
    {
        _factory = factory;
    }

    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    private static string NewEmail() => $"auth_{Guid.NewGuid():n}@test.local";

    [Fact]
    public async Task Register_ReturnsCreated_WithTokens()
    {
        var client = _factory.CreateClient();
        var email = NewEmail();

        var response = await client.PostAsJsonAsync("/api/auth/register", new
        {
            fullName = "Sita Sharma",
            email,
            password = "Passw0rd123",
            phoneNumber = "9811111111",
        });

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var auth = await response.Content.ReadFromJsonAsync<AuthResponse>(JsonOptions);
        Assert.NotNull(auth);
        Assert.False(string.IsNullOrWhiteSpace(auth!.AccessToken));
        Assert.False(string.IsNullOrWhiteSpace(auth.RefreshToken));
        Assert.Equal(email, auth.Email);
    }

    [Fact]
    public async Task Register_WithWeakPassword_Returns400WithThePolicyMessage()
    {
        // Identity rejects the password; that is a user error and must come back
        // as a 400 the register screen can display — not a 500 "unexpected error".
        var client = _factory.CreateClient();

        var response = await client.PostAsJsonAsync("/api/auth/register", new
        {
            fullName = "No Digits",
            email = NewEmail(),
            password = "onlyletters",
            phoneNumber = (string?)null,
        });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.Contains("digit", body, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task Register_WithDuplicateEmail_Returns400()
    {
        var client = _factory.CreateClient();
        var email = NewEmail();
        var payload = new { fullName = "Dup User", email, password = "Passw0rd123", phoneNumber = (string?)null };

        await client.PostAsJsonAsync("/api/auth/register", payload);
        var second = await client.PostAsJsonAsync("/api/auth/register", payload);

        Assert.Equal(HttpStatusCode.BadRequest, second.StatusCode);
    }

    [Fact]
    public async Task Register_WithInvalidInput_ReturnsValidationProblemDetails()
    {
        var client = _factory.CreateClient();

        var response = await client.PostAsJsonAsync("/api/auth/register", new
        {
            fullName = "",
            email = "bad-email",
            password = "short",
        });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        var problem = await response.Content.ReadFromJsonAsync<JsonElement>(JsonOptions);
        Assert.True(problem.TryGetProperty("errors", out _), "Validation problems must include an 'errors' extension.");
    }

    [Fact]
    public async Task Login_WithCorrectCredentials_ReturnsTokensAndEmptyBusinessList()
    {
        var client = _factory.CreateClient();
        var email = await RegisterUserAsync(client);

        var response = await client.PostAsJsonAsync("/api/auth/login", new
        {
            email,
            password = "Passw0rd123",
        });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var auth = await response.Content.ReadFromJsonAsync<AuthResponse>(JsonOptions);
        Assert.NotNull(auth!.AccessToken);
        Assert.Equal(email, auth.Email);
        Assert.Empty(auth.Businesses!);
    }

    [Fact]
    public async Task Login_WithWrongPassword_Returns401()
    {
        var client = _factory.CreateClient();
        var email = await RegisterUserAsync(client);

        var response = await client.PostAsJsonAsync("/api/auth/login", new
        {
            email,
            password = "WrongPassw0rd",
        });

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Me_WithValidToken_ReturnsProfile()
    {
        var client = await CreateAuthenticatedClientAsync();

        var response = await client.GetAsync("/api/auth/me");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var profile = await response.Content.ReadFromJsonAsync<UserProfileDto>(JsonOptions);
        Assert.Equal("Auth Tester", profile!.FullName);
    }

    [Fact]
    public async Task Me_WithoutToken_Returns401()
    {
        var client = _factory.CreateClient();

        var response = await client.GetAsync("/api/auth/me");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Refresh_WithValidRefreshToken_ReturnsFullUserInfo()
    {
        var client = _factory.CreateClient();
        var email = NewEmail();

        await client.PostAsJsonAsync("/api/auth/register", new
        {
            fullName = "Refresh Tester",
            email,
            password = "Passw0rd123",
            phoneNumber = (string?)null,
        });
        var login = await client.PostAsJsonAsync("/api/auth/login", new { email, password = "Passw0rd123" });
        var auth = await login.Content.ReadFromJsonAsync<AuthResponse>(JsonOptions);

        var response = await client.PostAsJsonAsync("/api/auth/refresh", new
        {
            refreshToken = auth!.RefreshToken,
        });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var refreshed = await response.Content.ReadFromJsonAsync<AuthResponse>(JsonOptions);

        // The old bug: refresh returned an empty user (id 0, empty email).
        Assert.Equal(auth.UserId, refreshed!.UserId);
        Assert.Equal(email, refreshed.Email);
        Assert.Equal("Refresh Tester", refreshed.FullName);
        Assert.NotEqual(auth.RefreshToken, refreshed.RefreshToken); // rotated
    }

    [Fact]
    public async Task Businesses_WithoutToken_Returns401()
    {
        var client = _factory.CreateClient();

        var response = await client.GetAsync("/api/businesses");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    // --- helpers ---

    private static async Task<string> RegisterUserAsync(HttpClient client)
    {
        var email = NewEmail();
        var response = await client.PostAsJsonAsync("/api/auth/register", new
        {
            fullName = "Auth Tester",
            email,
            password = "Passw0rd123",
            phoneNumber = (string?)null,
        });
        response.EnsureSuccessStatusCode();
        return email;
    }

    /// <summary>Registers and logs in a fresh user, returning a client with a bearer token.</summary>
    public static async Task<HttpClient> CreateAuthenticatedClientAsync(KhataApiFactory factory, string? email = null)
    {
        var client = factory.CreateClient();
        email ??= NewEmail();

        var register = await client.PostAsJsonAsync("/api/auth/register", new
        {
            fullName = "Auth Tester",
            email,
            password = "Passw0rd123",
            phoneNumber = (string?)null,
        });
        register.EnsureSuccessStatusCode();

        var login = await client.PostAsJsonAsync("/api/auth/login", new { email, password = "Passw0rd123" });
        login.EnsureSuccessStatusCode();
        var auth = await login.Content.ReadFromJsonAsync<AuthResponse>(JsonOptions);

        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", auth!.AccessToken);
        return client;
    }

    private Task<HttpClient> CreateAuthenticatedClientAsync() =>
        CreateAuthenticatedClientAsync(_factory);
}
