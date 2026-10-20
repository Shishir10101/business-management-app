using Khata.Api;
using Khata.Infrastructure.Data;
using Khata.Infrastructure.Identity;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Microsoft.Extensions.Hosting;

namespace Khata.Tests.Testing;

/// <summary>
/// Boots the real API against an in-memory SQLite database.
/// All integration tests share one factory (see <see cref="ApiTestCollection"/>) and
/// one database — use unique emails per test to stay isolated.
/// </summary>
public class KhataApiFactory : WebApplicationFactory<Program>
{
    private readonly SqliteConnection _connection = new("DataSource=:memory:");

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        // Skip Program.cs seeding — the factory seeds explicitly below.
        builder.UseEnvironment("Testing");

        // Keep generated PDFs out of the build output.
        builder.UseSetting("FileStorage:RootPath",
            Path.Combine(Path.GetTempPath(), "khata-tests-storage"));
    }

    private void SwapToSqlite(IServiceCollection services)
    {
        var dbOptionDescriptors = services.Where(d =>
            d.ServiceType == typeof(DbContextOptions<KhataDbContext>) ||
            d.ServiceType == typeof(DbContextOptions) ||
            (d.ServiceType.IsGenericType &&
             d.ServiceType.GetGenericTypeDefinition() == typeof(DbContextOptions<>))).ToList();
        foreach (var d in dbOptionDescriptors)
            services.Remove(d);

        services.RemoveAll<IDbContextOptionsConfiguration<KhataDbContext>>();

        var dbContextDescriptor = services.FirstOrDefault(d => d.ServiceType == typeof(KhataDbContext));
        if (dbContextDescriptor is not null)
            services.Remove(dbContextDescriptor);

        _connection.Open();
        services.AddDbContext<KhataDbContext>(options => options.UseSqlite(_connection));
    }

    protected override IHost CreateHost(IHostBuilder builder)
    {
        // The swap happens here (not in ConfigureWebHost): ConfigureServices callbacks
        // registered on this IHostBuilder run AFTER the application's own registrations,
        // so removing the Npgsql DbContext registration actually removes it. Doing the
        // swap in ConfigureWebHost instead leaves BOTH providers configured on the same
        // DbContextOptions instance ("Only a single database provider can be registered").
        builder.ConfigureServices(SwapToSqlite);

        var host = base.CreateHost(builder);

        // Create the schema from the model (not migrations — those are Npgsql-specific)
        // and seed system roles/permissions so business flows can run.
        using var scope = host.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<KhataDbContext>();
        db.Database.EnsureCreated();

        var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<AppRole>>();
        DatabaseSeeder.SeedPermissionsAsync(db).GetAwaiter().GetResult();
        DatabaseSeeder.SeedRolesAsync(roleManager, db).GetAwaiter().GetResult();
        DatabaseSeeder.SeedFeatureFlagsAsync(db).GetAwaiter().GetResult();

        return host;
    }

    protected override void Dispose(bool disposing)
    {
        _connection.Dispose();
        base.Dispose(disposing);
    }
}

/// <summary>Shared xunit collection: one API instance for all integration tests.</summary>
public static class ApiTestCollection
{
    public const string Name = "Api collection";
}

[CollectionDefinition(ApiTestCollection.Name)]
public class ApiCollectionDefinition : ICollectionFixture<KhataApiFactory>
{
}
