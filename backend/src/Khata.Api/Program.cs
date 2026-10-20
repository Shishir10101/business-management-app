using System.Text.Json.Serialization;
using FluentValidation;
using FluentValidation.AspNetCore;
using Khata.Infrastructure.Configuration;
using Khata.Infrastructure.Data;
using Khata.Infrastructure.Mongo;
using Microsoft.AspNetCore.Authorization;
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
        policy.WithOrigins(builder.Configuration["Cors:AllowedOrigins"]?.Split(",") ?? [])
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials();
    });
});

var app = builder.Build();

// --- Middleware Pipeline ---
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
