namespace Khata.Infrastructure.Configuration;

using Khata.Application.Interfaces;
using Khata.Infrastructure.Data;
using Khata.Infrastructure.Identity;
using Khata.Infrastructure.Mongo;
using Khata.Infrastructure.Services;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

public static class DependencyInjection
{
    public static IServiceCollection AddKhataInfrastructure(this IServiceCollection services, IConfiguration config)
    {
        // DbContext. The provider is chosen by the connection string: PostgreSQL for
        // production/development, SQLite (file or in-memory) when the connection string
        // starts with "DataSource=" — a zero-dependency local/demo mode.
        var connectionString = config.GetConnectionString("DefaultConnection") ?? string.Empty;
        if (connectionString.StartsWith("DataSource=", StringComparison.OrdinalIgnoreCase))
        {
            if (SqliteConnectionStrings.IsInMemory(connectionString))
            {
                // An in-memory database lives exactly as long as its only connection,
                // so every scoped DbContext must share this one instance. This is also
                // what the integration-test factory depends on.
                var connection = new Microsoft.Data.Sqlite.SqliteConnection(connectionString);
                connection.Open();
                // Singleton connection shared by all scoped DbContext instances.
                services.AddSingleton(connection);

                services.AddDbContext<KhataDbContext>(options =>
                    options.UseSqlite(connection));
            }
            else
            {
                // File-backed SQLite gets one connection per request, opened from the
                // connection string.
                //
                // This used to open a single connection at startup and share it across
                // every request. That is not supported: concurrent requests
                // interleaving on one connection produced genuine 500s under ordinary
                // browser load — "database is locked" and, because EF registers and
                // unregisters SQL functions per connection, "unable to delete/modify
                // user-function due to active statements". 21 of 744 logged requests
                // failed in one walk. The file keeps the data, so nothing needs to
                // hold a connection open for it to survive.
                //
                // The file stays in WAL mode (set by DatabaseSeeder), which allows any
                // number of concurrent readers plus one writer; busy_timeout makes the
                // writer wait its turn instead of failing.
                services.AddDbContext<KhataDbContext>(options => options
                    .UseSqlite(connectionString)
                    .AddInterceptors(new SqliteBusyTimeoutInterceptor()));
            }
        }
        else
        {
            services.AddDbContext<KhataDbContext>(options =>
                options.UseNpgsql(
                    connectionString,
                    npgsql => npgsql.MigrationsAssembly(typeof(KhataDbContext).Assembly.FullName)));
        }

        // --- MongoDB Atlas: the document store that sits beside the ledger ---
        // The ledger (sales, parties, items, payments, reports) stays on EF Core:
        // it is 26 foreign keys, 201 DTO projections and 21 GroupBy aggregates,
        // none of which the MongoDB EF Core provider supports. Atlas carries the
        // document-shaped data instead — audit trail, sync journal, notification
        // feed, backup snapshots. Registered unconditionally so IsEnabled is a
        // runtime answer rather than a DI-time one; nothing connects until a
        // connection string is present.
        services.Configure<MongoOptions>(config.GetSection(MongoOptions.SectionName));
        services.AddSingleton<KhataMongoContext>();

        // ASP.NET Core Identity
        services.AddIdentity<AppUser, AppRole>(options =>
        {
            // Password settings.
            //
            // 8 characters with only a digit requirement is below current
            // guidance and allowed "password1" style secrets. Requiring mixed
            // case costs the user nothing and closes the weakest half.
            options.Password.RequiredLength = 10;
            options.Password.RequireDigit = true;
            options.Password.RequireLowercase = true;
            options.Password.RequireUppercase = true;
            options.Password.RequireNonAlphanumeric = false;

            // Lockout settings
            options.Lockout.DefaultLockoutTimeSpan = TimeSpan.FromMinutes(15);
            options.Lockout.MaxFailedAccessAttempts = 5;
            options.Lockout.AllowedForNewUsers = true;

            // User settings
            options.User.RequireUniqueEmail = true;
            options.User.AllowedUserNameCharacters =
                "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._@+ ";

            // Sign-in settings
            options.SignIn.RequireConfirmedEmail = false;
            options.SignIn.RequireConfirmedPhoneNumber = false;
        })
        .AddEntityFrameworkStores<KhataDbContext>()
        .AddDefaultTokenProviders();

        // Application services
        services.AddSingleton<IModelCacheKeyFactory, KhataModelCacheKeyFactory>();
        services.AddScoped<ICurrentUserService>(sp =>
            CurrentUserService.FromClaims(
                sp.GetRequiredService<IHttpContextAccessor>().HttpContext?.User
                ?? new System.Security.Claims.ClaimsPrincipal()));
        services.AddScoped<IUnitOfWork, UnitOfWork>();
        services.AddScoped<ITokenService, JwtTokenService>();
        services.AddScoped<IAuthRepository, AuthRepository>();
        services.AddScoped<IBusinessService, BusinessService>();
        services.AddScoped<IProductService, ProductService>();
        services.AddScoped<IInventoryService, InventoryService>();
        services.AddScoped<IPartyService, PartyService>();
        services.AddScoped<ISaleService, SaleService>();
        services.AddScoped<IPurchaseService, PurchaseService>();
        services.AddScoped<IExpenseService, ExpenseService>();
        services.AddScoped<IIncomeService, IncomeService>();
        services.AddScoped<IPaymentService, PaymentService>();
        services.AddScoped<IPaymentMethodService, PaymentMethodService>();
        services.AddScoped<IInvoiceService, InvoiceService>();
        services.AddScoped<IQuotationService, QuotationService>();
        services.AddScoped<IReportService, ReportService>();
        services.AddScoped<ISyncService, SyncService>();
        services.AddScoped<INotificationService, NotificationService>();
        services.AddScoped<IReminderService, ReminderService>();
        services.AddScoped<IStatementService, StatementService>();
        services.AddScoped<IBackupService, BackupService>();
        services.AddScoped<IImportService, ImportService>();
        services.AddScoped<IAdminService, AdminService>();

        // Push delivery (FCM). No credentials ship with this repo, so the
        // dispatcher reports "disabled" and the in-app feed carries the load
        // until a Firebase project is configured.
        services.AddHttpClient("fcm", client => client.Timeout = TimeSpan.FromSeconds(15));
        services.AddScoped<INotificationDispatcher, Notifications.FcmNotificationDispatcher>();

        // Documents: QuestPDF rendering + local file storage (swap for an
        // S3-compatible implementation when credentials are available).
        services.AddSingleton<Khata.Application.Documents.IDocumentPdfGenerator,
            Documents.QuestPdfDocumentGenerator>();
        services.AddSingleton<IFileStorage, Storage.LocalFileStorage>();

        // Payment providers: cash settles immediately, everything else is manual
        // until real integrations (eSewa/Khalti/Fonepay) are wired up.
        services.AddSingleton<IPaymentProvider, Payments.CashPaymentProvider>();
        services.AddSingleton<IPaymentProvider, Payments.ManualPaymentProvider>();
        services.AddSingleton<IPaymentProviderRegistry, Payments.PaymentProviderRegistry>();

        services.AddSingleton<IDateTimeProvider, DateTimeProvider>();

        services.AddHttpContextAccessor();

        return services;
    }

    /// <summary>
    /// Seeds system roles and permissions on startup. Delegates to DatabaseSeeder.
    /// </summary>
    public static Task SeedAsync(this IServiceProvider services)
        => Data.DatabaseSeeder.SeedAsync(services);
}
