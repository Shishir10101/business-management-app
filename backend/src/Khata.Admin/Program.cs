namespace Khata.Admin;

using System.Security.Claims;
using Khata.Admin.Components;
using Khata.Admin.Services;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;

/// <summary>
/// Admin console entry point.
///
/// Declared explicitly (rather than with top-level statements) and inside the
/// Khata.Admin namespace: the API project already exposes a global `Program`
/// for its test host, and a second global one would make
/// `WebApplicationFactory&lt;Program&gt;` ambiguous in the test project.
/// </summary>
public class Program
{
    public static void Main(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);

        // Blazor Server: the API token stays server-side, inside an encrypted
        // auth cookie, so the browser never holds a readable admin JWT.
        builder.Services.AddRazorComponents()
            .AddInteractiveServerComponents();

        // Cookie authentication carries the API bearer token as a claim. This
        // is what makes [Authorize] work at BOTH layers: the HTTP endpoint
        // (so a deep link redirects to /login before the circuit starts) and
        // the Blazor circuit (AuthorizeRouteView).
        builder.Services
            .AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
            .AddCookie(options =>
            {
                options.LoginPath = "/login";
                options.AccessDeniedPath = "/login";
                options.Cookie.Name = "khata.admin";
                options.Cookie.HttpOnly = true;
                options.Cookie.SameSite = SameSiteMode.Strict;
                options.Cookie.SecurePolicy = CookieSecurePolicy.SameAsRequest;
                options.ExpireTimeSpan = TimeSpan.FromHours(8);
                options.SlidingExpiration = true;
            });
        builder.Services.AddAuthorization();
        builder.Services.AddCascadingAuthenticationState();

        // One HttpClient for the whole app; the typed client reads the token
        // from the circuit's auth state per request.
        var apiBaseUrl = builder.Configuration["KhataApi:BaseUrl"] ?? "http://localhost:5182";
        builder.Services.AddHttpClient<AdminApiClient>(client =>
        {
            client.BaseAddress = new Uri(apiBaseUrl.TrimEnd('/') + "/");
            client.Timeout = TimeSpan.FromSeconds(30);
        });

        var app = builder.Build();

        if (!app.Environment.IsDevelopment())
        {
            app.UseExceptionHandler("/Error", createScopeForErrors: true);
            app.UseHsts();
        }

        app.UseAuthentication();
        app.UseAuthorization();
        app.UseAntiforgery();

        // MapStaticAssets (not UseStaticFiles) is what serves the framework's
        // fingerprinted assets — including _framework/blazor.web.js, without
        // which no circuit ever starts.
        app.MapStaticAssets();

        MapAuthEndpoints(app);

        app.MapRazorComponents<App>()
            .AddInteractiveServerRenderMode();

        app.Run();
    }

    /// <summary>
    /// Sign-in / sign-out as plain form posts.
    ///
    /// Deliberately NOT Blazor-interactive: a cookie can only be set while a
    /// real HTTP request is in flight, and a circuit has no response to write
    /// to. A full-page form post is the honest way to do this, and it means
    /// the login page works even before the WebSocket connects.
    /// </summary>
    private static void MapAuthEndpoints(WebApplication app)
    {
        app.MapPost("/auth/signin", async (
            HttpContext http,
            AdminApiClient api,
            [Microsoft.AspNetCore.Mvc.FromForm] string email,
            [Microsoft.AspNetCore.Mvc.FromForm] string password,
            [Microsoft.AspNetCore.Mvc.FromForm] string? returnUrl) =>
        {
            if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(password))
                return Results.Redirect("/login?error=missing");

            AuthResponseLike auth;
            try
            {
                var result = await api.LoginAsync(email.Trim(), password);
                auth = new AuthResponseLike(result.AccessToken, result.UserId,
                    result.Email, result.FullName);
            }
            catch (AdminApiException)
            {
                return Results.Redirect("/login?error=credentials");
            }
            catch (HttpRequestException)
            {
                return Results.Redirect("/login?error=unreachable");
            }

            // Prove the account actually has admin.access before granting a
            // console session: a business account must not get in.
            var identity = new ClaimsIdentity(
                [
                    new Claim(ClaimTypes.NameIdentifier, auth.UserId.ToString()),
                    new Claim(ClaimTypes.Name, auth.FullName),
                    new Claim(ClaimTypes.Email, auth.Email),
                    new Claim(AdminApiClient.TokenClaim, auth.AccessToken),
                ],
                CookieAuthenticationDefaults.AuthenticationScheme);

            await http.SignInAsync(
                CookieAuthenticationDefaults.AuthenticationScheme,
                new ClaimsPrincipal(identity),
                new AuthenticationProperties { IsPersistent = false });

            var target = string.IsNullOrWhiteSpace(returnUrl) || !returnUrl.StartsWith('/')
                ? "/"
                : returnUrl;
            return Results.Redirect(target);
        }).DisableAntiforgery();

        app.MapPost("/auth/signout", async (HttpContext http) =>
        {
            await http.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
            return Results.Redirect("/login");
        }).DisableAntiforgery();
    }

    /// <summary>Small carrier so the sign-in endpoint does not need to import
    /// the API's DTO shape for four fields.</summary>
    private sealed record AuthResponseLike(
        string AccessToken, long UserId, string Email, string FullName);
}
