namespace Khata.Infrastructure.Data;

using Khata.Infrastructure.Identity;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Khata.Application.Common;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

/// <summary>
/// Seeds system roles and permissions. Idempotent — safe to call on every startup
/// and from integration tests against a fresh database.
/// </summary>
public static class DatabaseSeeder
{
    public static async Task SeedAsync(IServiceProvider services)
    {
        using var scope = services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<KhataDbContext>();
        var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<AppRole>>();

        // SQLite (demo/local mode) has no Npgsql migrations — create the schema
        // from the model instead.
        //
        // EnsureCreated is a no-op when ANY table already exists, so a database
        // file left over from an earlier build silently keeps its old schema:
        // new tables added later are never created and every request touching
        // them fails with "no such table: X". Detect that and rebuild from the
        // model, because a demo/local SQLite file is disposable by design.
        if (db.Database.IsSqlite())
        {
            var created = await db.Database.EnsureCreatedAsync();
            if (!created)
            {
                var expected = db.Model.GetEntityTypes()
                    .Select(e => e.GetTableName())
                    .Where(n => !string.IsNullOrEmpty(n))
                    .Distinct()
                    .ToList();

                var existing = await db.Database
                    .SqlQuery<string>($"SELECT name AS Value FROM sqlite_master WHERE type = 'table'")
                    .ToListAsync();

                var missing = expected.Except(existing).ToList();
                if (missing.Count > 0)
                {
                    // Stale schema from an older build — recreate from the model.
                    await RecreateFromModelAsync(db);
                }
                else
                {
                    // A new COLUMN (not a new table) also leaves the old schema
                    // in place: EnsureCreated only ever creates whole tables.
                    // Compare each table's columns against the model and rebuild
                    // on any drift — a demo file is disposable by design.
                    var staleColumns = await FindMissingColumnsAsync(db, existing);
                    Console.Error.WriteLine(
                        $"[schema-check] tables={existing.Count} staleColumns={staleColumns.Count} " +
                        string.Join(",", staleColumns.Take(8)));
                    if (staleColumns.Count > 0)
                    {
                        await RecreateFromModelAsync(db);
                    }
                }
            }
        }
        else
            await db.Database.MigrateAsync();

        if (db.Database.IsSqlite())
        {
            // WAL lets readers run while a writer holds the file, so the
            // mobile app's parallel requests (dashboard + customers +
            // suppliers + low-stock fire together) stop colliding with
            // SQLITE_BUSY. The default rollback journal takes an exclusive
            // lock and turns a normal concurrent request into a 500.
            await db.Database.ExecuteSqlRawAsync("PRAGMA journal_mode=WAL;");
        }

        await SeedPermissionsAsync(db);
        await SeedRolesAsync(roleManager, db);
        await SeedFeatureFlagsAsync(db);
        await SeedSuperAdminAsync(services, scope);
    }

    /// <summary>
    /// Ensures the platform has at least one SuperAdmin, because there is no
    /// other way to create the first one: the admin API is itself gated by
    /// admin.access.
    ///
    /// Only runs when there is no SuperAdmin yet. Credentials come from
    /// configuration (<c>Admin:Bootstrap:Email</c> / <c>Password</c>); when the
    /// database is SQLite (demo / local mode) a documented default is used so
    /// the console is reachable out of the box. A production deployment must
    /// set the configuration explicitly — no default password is ever created
    /// against a real database.
    /// </summary>
    public static async Task SeedSuperAdminAsync(IServiceProvider services, IServiceScope scope)
    {
        var db = scope.ServiceProvider.GetRequiredService<KhataDbContext>();
        var userManager = scope.ServiceProvider.GetRequiredService<UserManager<AppUser>>();

        var superAdminRole = await db.Roles
            .FirstOrDefaultAsync(r => r.Name == SystemRoles.SuperAdmin);
        if (superAdminRole is null) return;

        var alreadyExists = await (from ur in db.UserRoles
                                   where ur.RoleId == superAdminRole.Id
                                   select ur.UserId).AnyAsync();
        if (alreadyExists) return;

        var config = scope.ServiceProvider.GetRequiredService<IConfiguration>();
        var email = config["Admin:Bootstrap:Email"];
        var password = config["Admin:Bootstrap:Password"];

        if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(password))
        {
            // Demo/local only: a real deployment must opt in explicitly.
            if (!db.Database.IsSqlite()) return;

            email = "admin@khata.local";
            password = "Admin@12345";
        }

        var existingUser = await userManager.FindByEmailAsync(email);
        AppUser user;
        if (existingUser is null)
        {
            user = new AppUser
            {
                UserName = email,
                Email = email,
                FullName = "Platform Administrator",
                EmailConfirmed = true,
                IsActive = true,
                Locale = "en",
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow,
            };

            var created = await userManager.CreateAsync(user, password);
            if (!created.Succeeded)
            {
                var logger = scope.ServiceProvider
                    .GetService<ILoggerFactory>()
                    ?.CreateLogger(nameof(DatabaseSeeder));
                logger?.LogWarning(
                    "Bootstrap SuperAdmin could not be created for {Email}: {Errors}",
                    email, string.Join("; ", created.Errors.Select(e => e.Description)));
                return;
            }
        }
        else
        {
            user = existingUser;
        }

        await userManager.AddToRoleAsync(user, SystemRoles.SuperAdmin);
    }

    /// <summary>
    /// Table/column pairs the model expects but the database does not have.
    /// Used only for the SQLite demo path, where migrations are not applied.
    /// </summary>
    /// <summary>
    /// Drops the demo SQLite database and recreates it from the model.
    ///
    /// Also removes the WAL sidecar files: with journal_mode=WAL, deleting only
    /// the main file leaves -wal/-shm behind, and SQLite replays them over the
    /// fresh database — resurrecting exactly the stale schema we are trying to
    /// escape. That silent resurrection is why a column-drift rebuild appeared
    /// to do nothing.
    /// </summary>
    private static async Task RecreateFromModelAsync(KhataDbContext db)
    {
        var dataSource = db.Database.GetDbConnection() is { } conn
            ? conn.DataSource
            : null;

        // The connection MUST be closed first: an open handle keeps the deleted
        // file alive, and every later write lands in that ghost inode while new
        // requests open a different file at the same path — so the rebuild
        // appears to do nothing.
        await db.Database.CloseConnectionAsync();

        if (!string.IsNullOrEmpty(dataSource))
        {
            // Direct File.Delete rather than EnsureDeletedAsync: the EF helper
            // reopens a connection to drop the schema, which fails while the
            // scope's context is still live. Deleting the files (including the
            // WAL sidecars, which would otherwise be replayed over the fresh
            // database and resurrect the stale schema) and letting
            // EnsureCreatedAsync build from the model is both simpler and
            // actually works.
            foreach (var suffix in new[] { "", "-wal", "-shm", "-journal" })
            {
                var path = dataSource + suffix;
                try
                {
                    if (File.Exists(path))
                        File.Delete(path);
                }
                catch (IOException)
                {
                    // A locked sidecar will be recreated; the main-file
                    // rebuild is the important part.
                }
            }
        }

        await db.Database.EnsureCreatedAsync();
    }

    /// <summary>Column names of one SQLite table, via raw ADO.NET.</summary>
    private static async Task<List<string>> TableColumnsAsync(
        KhataDbContext db, string table)
    {
        var connection = db.Database.GetDbConnection();
        if (connection.State != System.Data.ConnectionState.Open)
            await connection.OpenAsync();

        var names = new List<string>();
        var command = connection.CreateCommand();
        command.CommandText = $"PRAGMA table_info('{table}');";
        using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
            names.Add(reader.GetString(1)); // column name is field 1
        return names;
    }

    private static async Task<List<string>> FindMissingColumnsAsync(
        KhataDbContext db, List<string> existingTables)
    {
        var missing = new List<string>();

        foreach (var entityType in db.Model.GetEntityTypes())
        {
            var table = entityType.GetTableName();
            if (string.IsNullOrEmpty(table) || !existingTables.Contains(table))
                continue; // whole-table drift is handled separately

            // Raw ADO.NET rather than EF's SqlQuery: the pragma table-valued
            // function is SQLite-specific and EF's translation of it is not
            // something to bet a schema check on.
            var actual = await TableColumnsAsync(db, table);

            foreach (var property in entityType.GetProperties())
            {
                var column = property.GetColumnName();
                if (string.IsNullOrEmpty(column))
                    continue;
                // Skip shadow FKs: their columns are created by the relationship,
                // not listed as properties on the entity.
                if (property.IsShadowProperty())
                    continue;
                if (!actual.Contains(column))
                    missing.Add($"{table}.{column}");
            }
        }

        return missing;
    }

    /// <summary>
    /// Default feature flags. Idempotent: only inserts flags whose key is
    /// absent, so a flag an admin has flipped stays flipped.
    /// </summary>
    public static async Task SeedFeatureFlagsAsync(KhataDbContext db)
    {
        var defaults = new (string Key, string Description)[]
        {
            ("esewa_payments", "eSewa payment integration"),
            ("khalti_payments", "Khalti payment integration"),
            ("qr_payments", "QR code payment display"),
            ("sms_reminders", "SMS reminder delivery"),
            ("email_notifications", "Email notification delivery"),
        };

        foreach (var (key, description) in defaults)
        {
            if (!await db.FeatureFlags.AnyAsync(f => f.Key == key))
            {
                db.FeatureFlags.Add(new Domain.Entities.FeatureFlag
                {
                    Key = key,
                    Description = description,
                    IsEnabled = false,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow,
                });
            }
        }

        await db.SaveChangesAsync();
    }

    public static async Task SeedPermissionsAsync(KhataDbContext db)
    {
        foreach (var (code, desc, category) in Permissions.All)
        {
            if (!await db.Permissions.AnyAsync(p => p.Code == code))
            {
                db.Permissions.Add(new Permission
                {
                    Code = code,
                    Description = desc,
                    Category = category,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow,
                });
            }
        }

        await db.SaveChangesAsync();
    }

    public static async Task SeedRolesAsync(RoleManager<AppRole> roleManager, KhataDbContext db)
    {
        var allPermissionIds = await db.Permissions.Select(p => p.Id).ToListAsync();

        var roles = new[]
        {
            (SystemRoles.Owner, "Business owner with full access"),
            (SystemRoles.Admin, "Business administrator"),
            (SystemRoles.Manager, "Business manager"),
            (SystemRoles.Accountant, "Accountant role"),
            (SystemRoles.SalesStaff, "Sales staff member"),
            (SystemRoles.InventoryStaff, "Inventory staff member"),
            (SystemRoles.Viewer, "Read-only access"),
            (SystemRoles.SuperAdmin, "Platform administrator (cross-tenant)"),
        };

        foreach (var (name, desc) in roles)
        {
            if (!await roleManager.RoleExistsAsync(name))
            {
                await roleManager.CreateAsync(new AppRole
                {
                    Name = name,
                    Description = desc,
                    IsSystem = true,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow,
                });
            }
        }

        // Assign permissions to roles
        var rolePermissionMap = new Dictionary<string, string[]>
        {
            // Business roles get every BUSINESS permission — never the
            // platform admin.access one. Granting it here would hand the
            // admin console to every business Owner.
            [SystemRoles.Owner] = (await db.Permissions
                .Where(p => p.Category != "admin")
                .Select(p => p.Id).ToListAsync())
                .Select(id => id.ToString()).ToArray(),
            [SystemRoles.Admin] = (await db.Permissions
                .Where(p => p.Category != "admin")
                .Select(p => p.Id).ToListAsync())
                .Select(id => id.ToString()).ToArray(),
            [SystemRoles.Manager] = (await db.Permissions
                .Where(p => p.Category == "sales" || p.Category == "purchase"
                    || p.Category == "inventory" || p.Category == "customers"
                    || p.Category == "suppliers" || p.Category == "expenses"
                    || p.Category == "income" || p.Category == "payments"
                    || p.Category == "invoices" || p.Category == "quotations"
                    || p.Category == "sync" || p.Category == "notifications"
                    || p.Category == "reminders" || p.Category == "import"
                    || p.Code == Permissions.ReportsView
                    || p.Code == Permissions.ReportsExport)
                .Select(p => p.Id).ToListAsync())
                .Select(id => id.ToString()).ToArray(),
            [SystemRoles.Accountant] = (await db.Permissions
                .Where(p => p.Category == "payments" || p.Category == "expenses"
                    || p.Category == "income" || p.Category == "sync"
                    || p.Category == "reminders"
                    || p.Code == Permissions.ReportsView
                    || p.Code == Permissions.ReportsExport
                    || p.Code == Permissions.KhataView)
                .Select(p => p.Id).ToListAsync())
                .Select(id => id.ToString()).ToArray(),
            [SystemRoles.SalesStaff] = (await db.Permissions
                .Where(p => p.Code == Permissions.SalesView || p.Code == Permissions.SalesCreate
                    || p.Code == Permissions.SalesEdit
                    || p.Code == Permissions.CustomersView || p.Code == Permissions.CustomersCreate
                    || p.Code == Permissions.SyncUse)
                .Select(p => p.Id).ToListAsync())
                .Select(id => id.ToString()).ToArray(),
            [SystemRoles.InventoryStaff] = (await db.Permissions
                .Where(p => p.Code == Permissions.InventoryView || p.Code == Permissions.InventoryCreate
                    || p.Code == Permissions.InventoryAdjust || p.Code == Permissions.ProductsView
                    || p.Code == Permissions.SyncUse)
                .Select(p => p.Id).ToListAsync())
                .Select(id => id.ToString()).ToArray(),
            [SystemRoles.Viewer] = (await db.Permissions
                .Where(p => p.Code.EndsWith(".view"))
                .Select(p => p.Id).ToListAsync())
                .Select(id => id.ToString()).ToArray(),
            // Platform role: the admin permission and NOTHING else — it must
            // never inherit business permissions.
            [SystemRoles.SuperAdmin] = (await db.Permissions
                .Where(p => p.Code == Permissions.AdminAccess)
                .Select(p => p.Id).ToListAsync())
                .Select(id => id.ToString()).ToArray(),
        };

        foreach (var (roleName, permissionIds) in rolePermissionMap)
        {
            var role = await roleManager.FindByNameAsync(roleName);
            if (role is null) continue;

            var existingPerms = await db.RolePermissions
                .Where(rp => rp.RoleId == role.Id)
                .Select(rp => rp.PermissionId)
                .ToListAsync();

            foreach (var permIdStr in permissionIds)
            {
                if (long.TryParse(permIdStr, out var permId) && !existingPerms.Contains(permId))
                {
                    db.RolePermissions.Add(new RolePermission
                    {
                        RoleId = role.Id,
                        PermissionId = permId,
                    });
                }
            }
        }

        await db.SaveChangesAsync();
    }
}
