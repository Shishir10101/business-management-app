namespace Khata.Admin;

using System.Security.Claims;
using Khata.Admin.Components;
using Khata.Admin.Services;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.HttpOverrides;

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
                // SameAsRequest is not good enough behind a TLS-terminating
                // proxy: the request the app sees is plain HTTP, so the cookie
                // would be issued without Secure and could travel over HTTP.
                // Local development is the only place that needs the lax value.
                options.Cookie.SecurePolicy = builder.Environment.IsDevelopment()
                    ? CookieSecurePolicy.SameAsRequest
                    : CookieSecurePolicy.Always;
                options.ExpireTimeSpan = TimeSpan.FromHours(8);
                options.SlidingExpiration = true;
            });
        builder.Services.AddAuthorization();
        builder.Services.AddCascadingAuthenticationState();

        // The console is a separate process from the API and is usually
        // deployed behind the same kind of proxy.
        builder.Services.Configure<ForwardedHeadersOptions>(options =>
        {
            options.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
            foreach (var cidr in new[] { "10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", "fc00::/7" })
                options.KnownIPNetworks.Add(System.Net.IPNetwork.Parse(cidr));
        });

        // One HttpClient for the whole app; the typed client reads the token
        // from the circuit's auth state per request.
        var apiBaseUrl = builder.Configuration["KhataApi:BaseUrl"] ?? "http://localhost:5182";
        builder.Services.AddHttpClient<AdminApiClient>(client =>
        {
            client.BaseAddress = new Uri(apiBaseUrl.TrimEnd('/') + "/");
            client.Timeout = TimeSpan.FromSeconds(30);
        });

        var app = builder.Build();

        app.UseForwardedHeaders();

        // Security headers. The console is an authenticated surface; it must not
        // be framed (clickjacking on the suspend/activate buttons) and its URLs
        // should not leak to third parties.
        app.Use(async (context, next) =>
        {
            var headers = context.Response.Headers;
            headers["X-Content-Type-Options"] = "nosniff";
            headers["X-Frame-Options"] = "DENY";
            headers["Referrer-Policy"] = "no-referrer";
            headers["X-Permitted-Cross-Domain-Policies"] = "none";
            await next();
        });

        if (!app.Environment.IsDevelopment())
        {
            app.UseExceptionHandler("/Error", createScopeForErrors: true);
            app.UseHsts();
            app.UseHttpsRedirection();
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
            // console session: a business account must not get in. The login
            // endpoint itself has no way to say "and this user is an admin", so
            // ask an admin-only endpoint with the fresh token.
            if (!await api.HasAdminAccessAsync(auth.AccessToken))
                return Results.Redirect("/login?error=forbidden");

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

            // Only a same-site path is a valid return target. A bare
            // StartsWith('/') also accepts "//evil.example", which a browser
            // reads as protocol-relative — an open redirect off the console.
            var target = IsLocalPath(returnUrl) ? returnUrl! : "/";
            return Results.Redirect(target);
        });

        app.MapPost("/auth/signout", async (HttpContext http) =>
        {
            // No antiforgery token here, and that is deliberate: this form lives
            // in MainLayout, which renders inside the Blazor circuit where
            // <AntiforgeryToken /> emits nothing — so a token would make the
            // button post an empty field and always 400.
            //
            // Two locks replace it. SameSite=Strict means the auth cookie is not
            // sent on a cross-site POST at all, and the Origin check below
            // rejects the request before it can clear the cookie. A forced
            // sign-out is a nuisance rather than a breach, but a console that
            // suspends tenants should not accept state changes from any page on
            // the internet.
            if (!IsSameOrigin(http.Request))
                return Results.Redirect("/login");

            await http.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
            return Results.Redirect("/login");
        }).DisableAntiforgery();
    }

    /// <summary>
    /// True when the request demonstrably came from this origin.
    /// </summary>
    /// <remarks>
    /// Browsers send <c>Origin</c> on every POST, including same-origin ones, so
    /// a missing header is treated as untrusted rather than waved through. The
    /// host comparison uses the request's own host, which behind a proxy is the
    /// public one because forwarded headers are enabled above.
    /// </remarks>
    private static bool IsSameOrigin(HttpRequest request)
    {
        var origin = request.Headers.Origin.ToString();
        if (string.IsNullOrEmpty(origin))
            return false;

        return Uri.TryCreate(origin, UriKind.Absolute, out var parsed)
            && string.Equals(parsed.Authority, request.Host.Value, StringComparison.OrdinalIgnoreCase);
    }

    /// <summary>
    /// True for a same-origin absolute path ("/users?page=2") and false for
    /// "//evil.example" or "/\evil.example", which browsers resolve to another
    /// host.
    /// </summary>
    private static bool IsLocalPath(string? url) =>
        !string.IsNullOrEmpty(url) && url[0] == '/'
        && (url.Length == 1 || (url[1] != '/' && url[1] != '\\'));

    /// <summary>Small carrier so the sign-in endpoint does not need to import
    /// the API's DTO shape for four fields.</summary>
    private sealed record AuthResponseLike(
        string AccessToken, long UserId, string Email, string FullName);
}
