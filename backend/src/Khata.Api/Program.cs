using System.Text.Json.Serialization;
using System.Threading.RateLimiting;
using FluentValidation;
using FluentValidation.AspNetCore;
using Khata.Infrastructure.Configuration;
using Khata.Infrastructure.Data;
using Khata.Infrastructure.Mongo;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.AspNetCore.RateLimiting;
using Serilog;

var builder = WebApplication.CreateBuilder(args);

// --- Serilog ---
builder.Host.UseSerilog((context, config) =>
    config.ReadFrom.Configuration(context.Configuration));

// --- Services ---
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter());
        options.JsonSerializerOptions.DefaultIgnoreCondition =
            System.Text.Json.Serialization.JsonIgnoreCondition.WhenWritingNull;
    });

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddOpenApi();

// --- Infrastructure (DbContext, Identity, Services) ---
builder.Services.AddKhataInfrastructure(builder.Configuration);

// --- FluentValidation (auto-validates request DTOs with registered validators) ---
builder.Services.AddFluentValidationAutoValidation();
builder.Services.AddValidatorsFromAssembly(typeof(Khata.Application.DTOs.RegisterRequest).Assembly);

// --- JWT Authentication ---
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = Microsoft.AspNetCore.Authentication.JwtBearer.JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = Microsoft.AspNetCore.Authentication.JwtBearer.JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new Microsoft.IdentityModel.Tokens.TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = builder.Configuration["Jwt:Issuer"],
        ValidAudience = builder.Configuration["Jwt:Audience"],
        IssuerSigningKey = new Microsoft.IdentityModel.Tokens.SymmetricSecurityKey(
            System.Text.Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Secret"]!)),
        ClockSkew = TimeSpan.FromMinutes(1)
    };
});

// --- Authorization (+ permission-code policies) ---
builder.Services.AddAuthorization();
builder.Services.AddSingleton<IAuthorizationPolicyProvider, Khata.Api.Authorization.PermissionPolicyProvider>();
builder.Services.AddScoped<IAuthorizationHandler, Khata.Api.Authorization.PermissionAuthorizationHandler>();

// --- Problem Details + exception handling ---
builder.Services.AddProblemDetails(options =>
{
    options.CustomizeProblemDetails = ctx =>
    {
        ctx.ProblemDetails.Extensions["traceId"] = ctx.HttpContext.TraceIdentifier;
    };
});
builder.Services.AddExceptionHandler<Khata.Api.Middleware.GlobalExceptionHandler>();

// --- CORS ---
builder.Services.AddCors(options =>
{
    options.AddPolicy("Default", policy =>
    {
        var origins = (builder.Configuration["Cors:AllowedOrigins"] ?? string.Empty)
            .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);

        // A mobile client sends no Origin header, so an empty list is a valid
        // deployment. WithOrigins("") would instead throw on the first
        // preflight request, which only shows up once a browser client exists.
        if (origins.Length > 0)
        {
            policy.WithOrigins(origins);
        }

        policy.AllowAnyHeader().AllowAnyMethod().AllowCredentials();
    });
});

// --- Reverse proxy (cloud hosting) ---
// Every PaaS terminates TLS at its edge and forwards plain HTTP, so without
// this the app cannot tell a request is already secure: UseHttpsRedirection
// would redirect endlessly and audit rows would record the proxy's IP instead
// of the client's. Safe locally, where there is no proxy to spoof.
builder.Services.Configure<ForwardedHeadersOptions>(options =>
{
    options.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
    // The proxy's address is assigned by the platform and not known in advance.
    // The platform network is the trust boundary here; do not run this on a host
    // that the public internet can reach directly.
    options.KnownIPNetworks.Clear();
    options.KnownProxies.Clear();
});

// --- Fail fast on a weak signing key ---
// HMAC-SHA256 needs 256 bits of key material. A short key does not fail at
// startup — it throws when the first user signs in, which reads as an outage
// rather than a misconfiguration. The shipped placeholder is public, so anyone
// who can read the repository could forge tokens signed with it.
const string PlaceholderJwtSecret =
    "CHANGE_ME_IN_PRODUCTION_USE_A_256_BIT_KEY_AT_LEAST_32_CHARACTERS_LONG_2026";

var jwtSecret = builder.Configuration["Jwt:Secret"];
if (string.IsNullOrWhiteSpace(jwtSecret) ||
    System.Text.Encoding.UTF8.GetByteCount(jwtSecret) < 32)
{
    throw new InvalidOperationException(
        "Jwt:Secret is missing or shorter than 32 bytes. Set Jwt__Secret to a random value of at " +
        "least 32 characters (for example: openssl rand -base64 48).");
}

if (jwtSecret == PlaceholderJwtSecret &&
    !builder.Environment.IsDevelopment() &&
    !builder.Environment.IsEnvironment("Testing"))
{
    throw new InvalidOperationException(
        "Jwt:Secret is still the placeholder committed to appsettings.json. Anyone with the " +
        "repository can forge tokens with it — set Jwt__Secret before deploying.");
}

// --- Rate limiting ---
// Per-account lockout already exists (5 tries / 15 minutes), but it cannot stop
// a spray of one password across thousands of accounts, and it lets anyone lock
// a known user out with five deliberate failures. Throttling per client IP
// closes both. RemoteIpAddress is only the real client because
// UseForwardedHeaders runs first.
var isTesting = builder.Environment.IsEnvironment("Testing");
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.AddPolicy("auth", context =>
        RateLimitPartition.GetFixedWindowLimiter(
            context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
            _ => new FixedWindowRateLimiterOptions
            {
                // The test suite shares one process and one client address, so a
                // real window would throttle the tests themselves.
                PermitLimit = isTesting ? int.MaxValue : 10,
                Window = TimeSpan.FromMinutes(1),
                QueueLimit = 0,
            }));

    // Everything else: a loose ceiling that only stops runaway loops or a
    // scraped endpoint, not normal use. The platform health check is exempt so
    // a burst of real traffic can never mark the service unhealthy.
    options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(context =>
    {
        if (context.Request.Path.StartsWithSegments("/health"))
        {
            return RateLimitPartition.GetNoLimiter("health");
        }

        return RateLimitPartition.GetFixedWindowLimiter(
            context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
            _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = isTesting ? int.MaxValue : 600,
                Window = TimeSpan.FromMinutes(1),
                QueueLimit = 0,
            });
    });
});

var app = builder.Build();

// --- Middleware Pipeline ---
app.UseForwardedHeaders();

// --- Security headers ---
app.Use(async (context, next) =>
{
    var headers = context.Response.Headers;
    headers["X-Content-Type-Options"] = "nosniff";
    headers["X-Frame-Options"] = "DENY";
    headers["Referrer-Policy"] = "no-referrer";
    headers["X-Permitted-Cross-Domain-Policies"] = "none";

    // Auth responses carry bearer tokens. Without this a shared proxy or a
    // browser cache can serve one user's token to the next request.
    if (context.Request.Path.StartsWithSegments("/api/auth"))
    {
        headers["Cache-Control"] = "no-store";
        headers["Pragma"] = "no-cache";
    }

    await next();
});

if (!app.Environment.IsDevelopment() && !isTesting)
{
    // One year, subdomains included. Only meaningful over HTTPS — which is what
    // forwarded headers make visible behind a cloud proxy.
    app.UseHsts();
}

app.UseRateLimiter();
app.UseExceptionHandler();
app.UseSerilogRequestLogging();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseCors("Default");
app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

// --- Health ---
// Reports both stores separately, because they fail for different reasons: the
// ledger is a connection string problem, Atlas is usually an IP allowlist or a
// paused free-tier cluster. Anonymous on purpose — a load balancer has no token.
app.MapGet("/health", async (KhataDbContext db, KhataMongoContext mongo, CancellationToken ct) =>
{
    var ledgerOk = false;
    string? ledgerError = null;
    try
    {
        ledgerOk = await db.Database.CanConnectAsync(ct);
    }
    catch (Exception ex)
    {
        ledgerError = ex.GetType().Name;
    }

    // Atlas being unconfigured is a valid deployment, not a failure.
    var atlasConfigured = mongo.IsEnabled;
    var atlasOk = atlasConfigured && await mongo.PingAsync(ct);

    var healthy = ledgerOk && (atlasOk || !atlasConfigured);

    return Results.Json(
        new
        {
            status = !ledgerOk ? "unhealthy" : healthy ? "ok" : "degraded",
            checks = new
            {
                ledger = new
                {
                    ok = ledgerOk,
                    provider = db.Database.ProviderName,
                    error = ledgerError
                },
                atlas = new
                {
                    configured = atlasConfigured,
                    ok = atlasOk,
                    database = mongo.Database?.DatabaseNamespace.DatabaseName
                }
            },
            at = DateTime.UtcNow
        },
        statusCode: healthy ? StatusCodes.Status200OK : StatusCodes.Status503ServiceUnavailable);
});

// --- Seed Database ---
if (!app.Environment.IsEnvironment("Testing"))
{
    try
    {
        await app.Services.SeedAsync();
        Log.Information("Database seeded successfully");
    }
    catch (Exception ex)
    {
        Log.Warning(ex, "Database seeding failed (may need to run migrations first)");
    }
}

// --- MongoDB Atlas indexes (idempotent, best-effort) ---
// Runs before the first request so the unique (BusinessId, OperationId) index
// is in place before any queued mobile operation can be replayed.
if (!app.Environment.IsEnvironment("Testing"))
{
    var mongo = app.Services.GetRequiredService<KhataMongoContext>();
    if (mongo.IsEnabled)
    {
        await mongo.EnsureIndexesAsync();
    }
}

app.Run();

// Exposed for WebApplicationFactory in integration tests.
public partial class Program;
