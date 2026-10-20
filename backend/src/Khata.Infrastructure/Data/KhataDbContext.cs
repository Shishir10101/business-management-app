namespace Khata.Infrastructure.Data;

using System.Linq.Expressions;
using System.Reflection;
using Khata.Application.Interfaces;
using Khata.Domain.Common;
using Khata.Infrastructure.Identity;
using Khata.Infrastructure.Services;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

/// <summary>
/// Main application DbContext. Extends IdentityDbContext for ASP.NET Core Identity.
/// Applies global query filters for tenant isolation (BusinessId) and soft deletion.
/// </summary>
public class KhataDbContext : IdentityDbContext<AppUser, AppRole, long>
{
    private readonly ICurrentUserService? _currentUserService;

    public KhataDbContext(DbContextOptions<KhataDbContext> options) : base(options) { }

    public KhataDbContext(
        DbContextOptions<KhataDbContext> options,
        ICurrentUserService currentUserService) : base(options)
    {
        _currentUserService = currentUserService;
        FilterBusinessId = currentUserService?.BusinessId ?? 0;
    }

    /// <summary>
    /// Business id snapshotted from the request's identity when this context was
    /// constructed. The tenant query filter compares against THIS (never a value
    /// baked into the cached model): the model cache key includes it, so a model
    /// built for business A can never be reused for business B. See
    /// <see cref="KhataModelCacheKeyFactory"/>.
    /// </summary>
    public long FilterBusinessId { get; } = 0;

    // Domain entities
    public DbSet<Domain.Entities.Business> Businesses => Set<Domain.Entities.Business>();
    public DbSet<Domain.Entities.BusinessMember> BusinessMembers => Set<Domain.Entities.BusinessMember>();
    public DbSet<Domain.Entities.BusinessBankAccount> BusinessBankAccounts => Set<Domain.Entities.BusinessBankAccount>();
    public DbSet<Domain.Entities.ProductCategory> ProductCategories => Set<Domain.Entities.ProductCategory>();
    public DbSet<Domain.Entities.Unit> Units => Set<Domain.Entities.Unit>();
    public DbSet<Domain.Entities.Product> Products => Set<Domain.Entities.Product>();
    public DbSet<Domain.Entities.ProductStock> ProductStocks => Set<Domain.Entities.ProductStock>();
    public DbSet<Domain.Entities.StockMovement> StockMovements => Set<Domain.Entities.StockMovement>();
    public DbSet<Domain.Entities.Customer> Customers => Set<Domain.Entities.Customer>();
    public DbSet<Domain.Entities.Supplier> Suppliers => Set<Domain.Entities.Supplier>();
    public DbSet<Domain.Entities.LedgerAccount> LedgerAccounts => Set<Domain.Entities.LedgerAccount>();
    public DbSet<Domain.Entities.LedgerTransaction> LedgerTransactions => Set<Domain.Entities.LedgerTransaction>();
    public DbSet<Domain.Entities.Sale> Sales => Set<Domain.Entities.Sale>();
    public DbSet<Domain.Entities.SaleItem> SaleItems => Set<Domain.Entities.SaleItem>();
    public DbSet<Domain.Entities.Purchase> Purchases => Set<Domain.Entities.Purchase>();
    public DbSet<Domain.Entities.PurchaseItem> PurchaseItems => Set<Domain.Entities.PurchaseItem>();
    public DbSet<Domain.Entities.Expense> Expenses => Set<Domain.Entities.Expense>();
    public DbSet<Domain.Entities.Income> Incomes => Set<Domain.Entities.Income>();
    public DbSet<Domain.Entities.DocumentSequence> DocumentSequences => Set<Domain.Entities.DocumentSequence>();
    public DbSet<Domain.Entities.PaymentMethod> PaymentMethods => Set<Domain.Entities.PaymentMethod>();
    public DbSet<Domain.Entities.Payment> Payments => Set<Domain.Entities.Payment>();
    public DbSet<Domain.Entities.Invoice> Invoices => Set<Domain.Entities.Invoice>();
    public DbSet<Domain.Entities.InvoiceItem> InvoiceItems => Set<Domain.Entities.InvoiceItem>();
    public DbSet<Domain.Entities.Quotation> Quotations => Set<Domain.Entities.Quotation>();
    public DbSet<Domain.Entities.QuotationItem> QuotationItems => Set<Domain.Entities.QuotationItem>();
    public DbSet<Domain.Entities.SyncOperation> SyncOperations => Set<Domain.Entities.SyncOperation>();
    public DbSet<Domain.Entities.Notification> Notifications => Set<Domain.Entities.Notification>();
    public DbSet<Domain.Entities.DeviceRegistration> DeviceRegistrations => Set<Domain.Entities.DeviceRegistration>();
    public DbSet<Domain.Entities.NotificationSettings> NotificationSettings => Set<Domain.Entities.NotificationSettings>();
    public DbSet<Domain.Entities.Reminder> Reminders => Set<Domain.Entities.Reminder>();
    public DbSet<Domain.Entities.BackupRestoreEntry> BackupRestoreEntries => Set<Domain.Entities.BackupRestoreEntry>();

    // Platform admin (deliberately NOT IBusinessEntity — the admin console
    // reads across all tenants, so no business query filter applies)
    public DbSet<Domain.Entities.AuditLog> AuditLogs => Set<Domain.Entities.AuditLog>();
    public DbSet<Domain.Entities.FeatureFlag> FeatureFlags => Set<Domain.Entities.FeatureFlag>();
    public DbSet<Domain.Entities.SupportTicket> SupportTickets => Set<Domain.Entities.SupportTicket>();

    // Identity entities
    public DbSet<Permission> Permissions => Set<Permission>();
    public DbSet<RolePermission> RolePermissions => Set<RolePermission>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        // Rename Identity tables to snake_case
        builder.Entity<AppUser>(entity =>
        {
            entity.ToTable("app_user");
            entity.Property(u => u.FullName).HasMaxLength(200).IsRequired();
            entity.Property(u => u.Locale).HasMaxLength(10).HasDefaultValue("ne");
            entity.Property(u => u.Timezone).HasMaxLength(50).HasDefaultValue("Asia/Kathmandu");
            entity.Property(u => u.ProfileImageUrl).HasMaxLength(512);
            entity.HasIndex(u => u.ActiveBusinessId);
        });

        builder.Entity<AppRole>(entity =>
        {
            entity.ToTable("app_role");
            entity.Property(r => r.Description).HasMaxLength(500);
        });

        builder.Entity<IdentityUserRole<long>>().ToTable("app_user_role");
        builder.Entity<IdentityUserClaim<long>>().ToTable("app_user_claim");
        builder.Entity<IdentityUserLogin<long>>().ToTable("app_user_login");
        builder.Entity<IdentityUserToken<long>>().ToTable("app_user_token");
        builder.Entity<IdentityRoleClaim<long>>().ToTable("app_role_claim");

        // Permission entity
        builder.Entity<Permission>(entity =>
        {
            entity.ToTable("permission");
            entity.HasKey(p => p.Id);
            entity.Property(p => p.Code).HasMaxLength(100).IsRequired();
            entity.Property(p => p.Description).HasMaxLength(500);
            entity.Property(p => p.Category).HasMaxLength(50).IsRequired();
            entity.HasIndex(p => p.Code).IsUnique();
        });

        // RolePermission join entity
        builder.Entity<RolePermission>(entity =>
        {
            entity.ToTable("role_permission");
            entity.HasKey(rp => new { rp.RoleId, rp.PermissionId });
            entity.HasOne(rp => rp.Role)
                .WithMany(r => r.RolePermissions)
                .HasForeignKey(rp => rp.RoleId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(rp => rp.Permission)
                .WithMany(p => p.RolePermissions)
                .HasForeignKey(rp => rp.PermissionId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // Business entity configuration
        builder.Entity<Domain.Entities.Business>(entity =>
        {
            entity.ToTable("business");
            entity.HasKey(b => b.Id);
            entity.Property(b => b.Name).HasMaxLength(200).IsRequired();
            entity.Property(b => b.Type).HasMaxLength(50);
            entity.Property(b => b.PanNumber).HasMaxLength(50);
            entity.Property(b => b.PhoneNumber).HasMaxLength(20);
            entity.Property(b => b.Email).HasMaxLength(256);
            entity.Property(b => b.AddressLine).HasMaxLength(500);
            entity.Property(b => b.City).HasMaxLength(100);
            entity.Property(b => b.District).HasMaxLength(100);

            // Province and WardNumber are integers so province-level reporting
            // can group on them. The range rules are advisory here (a CHECK
            // constraint would need a migration per rule change); validators
            // reject out-of-range values at the API boundary, and the
            // 2026-10-15 migration coerces the legacy free text.
            entity.Property(b => b.Province);
            entity.Property(b => b.WardNumber);

            entity.Property(b => b.LogoUrl).HasMaxLength(512);
            entity.Property(b => b.Currency).HasMaxLength(10).HasDefaultValue("NPR");
            entity.Property(b => b.IsActive).HasDefaultValue(true);
            entity.HasIndex(b => b.Name);
            entity.HasIndex(b => b.DeletedAt);
        });

        // BusinessMember entity configuration
        builder.Entity<Domain.Entities.BusinessMember>(entity =>
        {
            entity.ToTable("business_member");
            entity.HasKey(bm => bm.Id);
            entity.Property(bm => bm.BusinessId).IsRequired();
            entity.Property(bm => bm.UserId).IsRequired();
            entity.Property(bm => bm.RoleId).IsRequired();
            entity.Property(bm => bm.IsActive).HasDefaultValue(true);
            entity.HasIndex(bm => new { bm.BusinessId, bm.UserId }).IsUnique();
            entity.HasIndex(bm => bm.UserId);
            entity.HasIndex(bm => bm.BusinessId);

            // Explicit relationship: UserId is the FK to the user. Without this, the
            // AppUser.BusinessMemberships collection navigation makes EF convention
            // create a shadow "AppUserId" FK column that stays null on insert.
            entity.HasOne<AppUser>()
                .WithMany(u => u.BusinessMemberships)
                .HasForeignKey(bm => bm.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // BusinessBankAccount entity configuration
        builder.Entity<Domain.Entities.BusinessBankAccount>(entity =>
        {
            entity.ToTable("business_bank_account");
            entity.HasKey(ba => ba.Id);
            entity.Property(ba => ba.BankName).HasMaxLength(200).IsRequired();
            entity.Property(ba => ba.AccountName).HasMaxLength(200).IsRequired();
            entity.Property(ba => ba.AccountNumber).HasMaxLength(50).IsRequired();
            entity.Property(ba => ba.Branch).HasMaxLength(200);
            entity.Property(ba => ba.IsDefault).HasDefaultValue(false);
            entity.Property(ba => ba.IsActive).HasDefaultValue(true);
            entity.HasIndex(ba => ba.BusinessId);
        });

        // ProductCategory entity configuration
        builder.Entity<Domain.Entities.ProductCategory>(entity =>
        {
            entity.ToTable("product_category");
            entity.HasKey(c => c.Id);
            entity.Property(c => c.BusinessId).IsRequired();
            entity.Property(c => c.Name).HasMaxLength(200).IsRequired();
            entity.Property(c => c.Description).HasMaxLength(1000);
            entity.Property(c => c.IsActive).HasDefaultValue(true);
            entity.HasIndex(c => c.BusinessId);
            entity.HasIndex(c => new { c.BusinessId, c.Name });

            // Self-referencing parent/children (nested categories)
            entity.HasOne(c => c.Parent)
                .WithMany(c => c.Children)
                .HasForeignKey(c => c.ParentId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // Unit entity configuration
        builder.Entity<Domain.Entities.Unit>(entity =>
        {
            entity.ToTable("unit");
            entity.HasKey(u => u.Id);
            entity.Property(u => u.BusinessId).IsRequired();
            entity.Property(u => u.Name).HasMaxLength(50).IsRequired();
            entity.Property(u => u.ShortName).HasMaxLength(10).IsRequired();
            entity.Property(u => u.IsActive).HasDefaultValue(true);
            entity.HasIndex(u => new { u.BusinessId, u.Name }).IsUnique();
            entity.HasIndex(u => u.BusinessId);
        });

        // Product entity configuration
        builder.Entity<Domain.Entities.Product>(entity =>
        {
            entity.ToTable("product");
            entity.HasKey(p => p.Id);
            entity.Property(p => p.BusinessId).IsRequired();
            entity.Property(p => p.Name).HasMaxLength(200).IsRequired();
            entity.Property(p => p.Sku).HasMaxLength(100);
            entity.Property(p => p.Barcode).HasMaxLength(100);
            entity.Property(p => p.Description).HasMaxLength(2000);
            entity.Property(p => p.ImageUrl).HasMaxLength(512);
            entity.Property(p => p.IsActive).HasDefaultValue(true);
            entity.HasIndex(p => p.BusinessId);
            entity.HasIndex(p => new { p.BusinessId, p.Name });
            entity.HasIndex(p => new { p.BusinessId, p.Sku });
            entity.HasIndex(p => new { p.BusinessId, p.Barcode });

            entity.HasOne(p => p.Category)
                .WithMany(c => c.Products)
                .HasForeignKey(p => p.CategoryId)
                .OnDelete(DeleteBehavior.SetNull);

            entity.HasOne(p => p.Unit)
                .WithMany(u => u.Products)
                .HasForeignKey(p => p.UnitId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        // ProductStock entity configuration
        builder.Entity<Domain.Entities.ProductStock>(entity =>
        {
            entity.ToTable("stock");
            entity.HasKey(s => s.Id);
            entity.Property(s => s.BusinessId).IsRequired();
            entity.Property(s => s.ProductId).IsRequired();
            entity.Property(s => s.Quantity).HasPrecision(18, 3);
            entity.Property(s => s.MinQuantity).HasPrecision(18, 3);
            entity.HasIndex(s => new { s.BusinessId, s.ProductId }).IsUnique();

            entity.HasOne(s => s.Product)
                .WithOne(p => p.Stock)
                .HasForeignKey<Domain.Entities.ProductStock>(s => s.ProductId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // StockMovement entity configuration (immutable ledger)
        builder.Entity<Domain.Entities.StockMovement>(entity =>
        {
            entity.ToTable("stock_movement");
            entity.HasKey(m => m.Id);
            entity.Property(m => m.BusinessId).IsRequired();
            entity.Property(m => m.ProductId).IsRequired();
            entity.Property(m => m.Quantity).HasPrecision(18, 3);
            entity.Property(m => m.BalanceAfter).HasPrecision(18, 3);
            entity.Property(m => m.ReferenceType).HasMaxLength(30);
            entity.Property(m => m.Notes).HasMaxLength(1000);
            entity.HasIndex(m => new { m.ProductId, m.MovementDate });
            entity.HasIndex(m => new { m.BusinessId, m.MovementDate });
            entity.HasIndex(m => new { m.ReferenceType, m.ReferenceId });

            entity.HasOne(m => m.Product)
                .WithMany()
                .HasForeignKey(m => m.ProductId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // Customer entity configuration
        builder.Entity<Domain.Entities.Customer>(entity =>
        {
            entity.ToTable("customer");
            entity.HasKey(c => c.Id);
            entity.Property(c => c.BusinessId).IsRequired();
            entity.Property(c => c.Name).HasMaxLength(200).IsRequired();
            entity.Property(c => c.PhoneNumber).HasMaxLength(20);
            entity.Property(c => c.Email).HasMaxLength(256);
            entity.Property(c => c.AddressLine).HasMaxLength(500);
            entity.Property(c => c.City).HasMaxLength(100);
            entity.Property(c => c.District).HasMaxLength(100);
            entity.Property(c => c.PanNumber).HasMaxLength(50);
            entity.Property(c => c.Notes).HasMaxLength(1000);
            entity.Property(c => c.IsActive).HasDefaultValue(true);
            entity.HasIndex(c => c.BusinessId);
            entity.HasIndex(c => new { c.BusinessId, c.Name });
            entity.HasIndex(c => new { c.BusinessId, c.PhoneNumber });
        });

        // Supplier entity configuration
        builder.Entity<Domain.Entities.Supplier>(entity =>
        {
            entity.ToTable("supplier");
            entity.HasKey(s => s.Id);
            entity.Property(s => s.BusinessId).IsRequired();
            entity.Property(s => s.Name).HasMaxLength(200).IsRequired();
            entity.Property(s => s.PhoneNumber).HasMaxLength(20);
            entity.Property(s => s.Email).HasMaxLength(256);
            entity.Property(s => s.AddressLine).HasMaxLength(500);
            entity.Property(s => s.City).HasMaxLength(100);
            entity.Property(s => s.District).HasMaxLength(100);
            entity.Property(s => s.PanNumber).HasMaxLength(50);
            entity.Property(s => s.Notes).HasMaxLength(1000);
            entity.Property(s => s.IsActive).HasDefaultValue(true);
            entity.HasIndex(s => s.BusinessId);
            entity.HasIndex(s => new { s.BusinessId, s.Name });
            entity.HasIndex(s => new { s.BusinessId, s.PhoneNumber });
        });

        // LedgerAccount entity configuration (polymorphic party reference)
        builder.Entity<Domain.Entities.LedgerAccount>(entity =>
        {
            entity.ToTable("ledger_account");
            entity.HasKey(a => a.Id);
            entity.Property(a => a.BusinessId).IsRequired();
            entity.Property(a => a.PartyType).HasMaxLength(10).HasConversion<string>();
            entity.Property(a => a.PartyId).IsRequired();
            entity.HasIndex(a => new { a.BusinessId, a.PartyType, a.PartyId }).IsUnique();
            entity.HasIndex(a => new { a.BusinessId, a.PartyType });
        });

        // LedgerTransaction entity configuration (immutable khata ledger)
        builder.Entity<Domain.Entities.LedgerTransaction>(entity =>
        {
            entity.ToTable("ledger_transaction");
            entity.HasKey(t => t.Id);
            entity.Property(t => t.BusinessId).IsRequired();
            entity.Property(t => t.LedgerAccountId).IsRequired();
            entity.Property(t => t.TransactionType).HasMaxLength(10).HasConversion<string>();
            entity.Property(t => t.Amount).IsRequired();
            entity.Property(t => t.BalanceAfter).IsRequired();
            entity.Property(t => t.ReferenceType).HasMaxLength(20);
            entity.Property(t => t.Description).HasMaxLength(500);
            entity.HasIndex(t => new { t.LedgerAccountId, t.TransactionDate });
            entity.HasIndex(t => new { t.BusinessId, t.TransactionDate });
            entity.HasIndex(t => new { t.ReferenceType, t.ReferenceId });

            entity.HasOne(t => t.LedgerAccount)
                .WithMany(a => a.Transactions)
                .HasForeignKey(t => t.LedgerAccountId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // RefreshToken entity
        builder.Entity<RefreshToken>(entity =>
        {
            entity.ToTable("refresh_token");
            entity.HasKey(rt => rt.Id);
            entity.Property(rt => rt.TokenHash).HasMaxLength(128).IsRequired();
            entity.HasIndex(rt => rt.TokenHash).IsUnique();
            entity.HasIndex(rt => rt.UserId);
            entity.Property(rt => rt.ExpiresAt).IsRequired();
            entity.Property(rt => rt.CreatedAt).IsRequired();
        });

        // Sale entity configuration (invoice number unique per business)
        builder.Entity<Domain.Entities.Sale>(entity =>
        {
            entity.ToTable("sale");
            entity.HasKey(s => s.Id);
            entity.Property(s => s.BusinessId).IsRequired();
            entity.Property(s => s.InvoiceNumber).HasMaxLength(30).IsRequired();
            entity.Property(s => s.SaleType).HasMaxLength(20).HasConversion<string>();
            entity.Property(s => s.PaymentStatus).HasMaxLength(20).HasConversion<string>();
            entity.Property(s => s.Notes).HasMaxLength(1000);
            entity.HasIndex(s => new { s.BusinessId, s.InvoiceNumber }).IsUnique();
            entity.HasIndex(s => new { s.BusinessId, s.SaleDate });
            entity.HasIndex(s => new { s.BusinessId, s.CustomerId });
            entity.HasIndex(s => s.DeletedAt);

            entity.HasOne(s => s.Customer)
                .WithMany()
                .HasForeignKey(s => s.CustomerId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        // SaleItem entity configuration
        builder.Entity<Domain.Entities.SaleItem>(entity =>
        {
            entity.ToTable("sale_item");
            entity.HasKey(i => i.Id);
            entity.Property(i => i.BusinessId).IsRequired();
            entity.Property(i => i.ProductName).HasMaxLength(200).IsRequired();
            entity.Property(i => i.Quantity).HasPrecision(18, 3);
            entity.HasIndex(i => i.SaleId);
            entity.HasIndex(i => new { i.BusinessId, i.ProductId });

            entity.HasOne(i => i.Sale)
                .WithMany(s => s.Items)
                .HasForeignKey(i => i.SaleId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(i => i.Product)
                .WithMany()
                .HasForeignKey(i => i.ProductId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // Purchase entity configuration (bill number unique per business)
        builder.Entity<Domain.Entities.Purchase>(entity =>
        {
            entity.ToTable("purchase");
            entity.HasKey(p => p.Id);
            entity.Property(p => p.BusinessId).IsRequired();
            entity.Property(p => p.BillNumber).HasMaxLength(30).IsRequired();
            entity.Property(p => p.PurchaseType).HasMaxLength(20).HasConversion<string>();
            entity.Property(p => p.PaymentStatus).HasMaxLength(20).HasConversion<string>();
            entity.Property(p => p.Notes).HasMaxLength(1000);
            entity.HasIndex(p => new { p.BusinessId, p.BillNumber }).IsUnique();
            entity.HasIndex(p => new { p.BusinessId, p.PurchaseDate });
            entity.HasIndex(p => new { p.BusinessId, p.SupplierId });
            entity.HasIndex(p => p.DeletedAt);

            entity.HasOne(p => p.Supplier)
                .WithMany()
                .HasForeignKey(p => p.SupplierId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        // PurchaseItem entity configuration
        builder.Entity<Domain.Entities.PurchaseItem>(entity =>
        {
            entity.ToTable("purchase_item");
            entity.HasKey(i => i.Id);
            entity.Property(i => i.BusinessId).IsRequired();
            entity.Property(i => i.ProductName).HasMaxLength(200).IsRequired();
            entity.Property(i => i.Quantity).HasPrecision(18, 3);
            entity.HasIndex(i => i.PurchaseId);
            entity.HasIndex(i => new { i.BusinessId, i.ProductId });

            entity.HasOne(i => i.Purchase)
                .WithMany(p => p.Items)
                .HasForeignKey(i => i.PurchaseId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(i => i.Product)
                .WithMany()
                .HasForeignKey(i => i.ProductId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // Expense entity configuration
        builder.Entity<Domain.Entities.Expense>(entity =>
        {
            entity.ToTable("expense");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.BusinessId).IsRequired();
            entity.Property(e => e.Category).HasMaxLength(100).IsRequired();
            entity.Property(e => e.Description).HasMaxLength(1000);
            entity.Property(e => e.PaymentMethod).HasMaxLength(30);
            entity.Property(e => e.Reference).HasMaxLength(100);
            entity.Property(e => e.Notes).HasMaxLength(1000);
            entity.HasIndex(e => new { e.BusinessId, e.ExpenseDate });
            entity.HasIndex(e => new { e.BusinessId, e.Category });
            entity.HasIndex(e => e.DeletedAt);
        });

        // Income entity configuration
        builder.Entity<Domain.Entities.Income>(entity =>
        {
            entity.ToTable("income");
            entity.HasKey(i => i.Id);
            entity.Property(i => i.BusinessId).IsRequired();
            entity.Property(i => i.Source).HasMaxLength(100).IsRequired();
            entity.Property(i => i.Description).HasMaxLength(1000);
            entity.Property(i => i.PaymentMethod).HasMaxLength(30);
            entity.Property(i => i.Reference).HasMaxLength(100);
            entity.Property(i => i.Notes).HasMaxLength(1000);
            entity.HasIndex(i => new { i.BusinessId, i.IncomeDate });
            entity.HasIndex(i => new { i.BusinessId, i.Source });
            entity.HasIndex(i => i.DeletedAt);
        });

        // DocumentSequence entity configuration (atomic per-business numbering)
        builder.Entity<Domain.Entities.DocumentSequence>(entity =>
        {
            entity.ToTable("document_sequence");
            entity.HasKey(d => d.Id);
            entity.Property(d => d.BusinessId).IsRequired();
            entity.Property(d => d.DocumentType).HasMaxLength(30).IsRequired();
            entity.HasIndex(d => new { d.BusinessId, d.DocumentType }).IsUnique();
        });

        // PaymentMethod entity configuration
        builder.Entity<Domain.Entities.PaymentMethod>(entity =>
        {
            entity.ToTable("payment_method");
            entity.HasKey(m => m.Id);
            entity.Property(m => m.BusinessId).IsRequired();
            entity.Property(m => m.Name).HasMaxLength(100).IsRequired();
            entity.Property(m => m.Code).HasMaxLength(30).IsRequired();
            entity.Property(m => m.Description).HasMaxLength(500);
            entity.Property(m => m.IsActive).HasDefaultValue(true);
            entity.Property(m => m.IsDefault).HasDefaultValue(false);
            entity.HasIndex(m => new { m.BusinessId, m.Name }).IsUnique();
            entity.HasIndex(m => m.BusinessId);
        });

        // Payment entity configuration (immutable money record)
        builder.Entity<Domain.Entities.Payment>(entity =>
        {
            entity.ToTable("payment");
            entity.HasKey(p => p.Id);
            entity.Property(p => p.BusinessId).IsRequired();
            entity.Property(p => p.PartyType).HasMaxLength(10).HasConversion<string>();
            entity.Property(p => p.Direction).HasMaxLength(10).HasConversion<string>();
            entity.Property(p => p.MethodName).HasMaxLength(100);
            entity.Property(p => p.Reference).HasMaxLength(100);
            entity.Property(p => p.Notes).HasMaxLength(1000);
            entity.HasIndex(p => new { p.BusinessId, p.PaymentDate });
            entity.HasIndex(p => new { p.BusinessId, p.PartyType, p.PartyId });
            entity.HasIndex(p => p.SaleId);
            entity.HasIndex(p => p.PurchaseId);

            entity.HasOne(p => p.PaymentMethod)
                .WithMany()
                .HasForeignKey(p => p.PaymentMethodId)
                .OnDelete(DeleteBehavior.SetNull);

            entity.HasOne(p => p.Sale)
                .WithMany()
                .HasForeignKey(p => p.SaleId)
                .OnDelete(DeleteBehavior.SetNull);

            entity.HasOne(p => p.Purchase)
                .WithMany()
                .HasForeignKey(p => p.PurchaseId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        // Invoice entity configuration (number unique per business)
        builder.Entity<Domain.Entities.Invoice>(entity =>
        {
            entity.ToTable("invoice");
            entity.HasKey(i => i.Id);
            entity.Property(i => i.BusinessId).IsRequired();
            entity.Property(i => i.InvoiceNumber).HasMaxLength(30).IsRequired();
            entity.Property(i => i.Status).HasMaxLength(20).HasConversion<string>();
            entity.Property(i => i.Notes).HasMaxLength(2000);
            entity.Property(i => i.Terms).HasMaxLength(2000);
            entity.Property(i => i.PdfPath).HasMaxLength(512);
            entity.HasIndex(i => new { i.BusinessId, i.InvoiceNumber }).IsUnique();
            entity.HasIndex(i => new { i.BusinessId, i.IssueDate });
            entity.HasIndex(i => new { i.BusinessId, i.CustomerId });
            entity.HasIndex(i => i.DeletedAt);

            entity.HasOne(i => i.Customer)
                .WithMany()
                .HasForeignKey(i => i.CustomerId)
                .OnDelete(DeleteBehavior.SetNull);

            entity.HasOne(i => i.Sale)
                .WithMany()
                .HasForeignKey(i => i.SaleId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        // InvoiceItem entity configuration
        builder.Entity<Domain.Entities.InvoiceItem>(entity =>
        {
            entity.ToTable("invoice_item");
            entity.HasKey(i => i.Id);
            entity.Property(i => i.BusinessId).IsRequired();
            entity.Property(i => i.Description).HasMaxLength(300).IsRequired();
            entity.Property(i => i.Quantity).HasPrecision(18, 3);
            entity.HasIndex(i => i.InvoiceId);

            entity.HasOne(i => i.Invoice)
                .WithMany(x => x.Items)
                .HasForeignKey(i => i.InvoiceId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(i => i.Product)
                .WithMany()
                .HasForeignKey(i => i.ProductId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        // Quotation entity configuration (number unique per business)
        builder.Entity<Domain.Entities.Quotation>(entity =>
        {
            entity.ToTable("quotation");
            entity.HasKey(q => q.Id);
            entity.Property(q => q.BusinessId).IsRequired();
            entity.Property(q => q.QuoteNumber).HasMaxLength(30).IsRequired();
            entity.Property(q => q.Status).HasMaxLength(20).HasConversion<string>();
            entity.Property(q => q.Notes).HasMaxLength(2000);
            entity.Property(q => q.Terms).HasMaxLength(2000);
            entity.Property(q => q.PdfPath).HasMaxLength(512);
            entity.HasIndex(q => new { q.BusinessId, q.QuoteNumber }).IsUnique();
            entity.HasIndex(q => new { q.BusinessId, q.IssueDate });
            entity.HasIndex(q => q.DeletedAt);

            entity.HasOne(q => q.Customer)
                .WithMany()
                .HasForeignKey(q => q.CustomerId)
                .OnDelete(DeleteBehavior.SetNull);

            entity.HasOne(q => q.ConvertedSale)
                .WithMany()
                .HasForeignKey(q => q.ConvertedSaleId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        // QuotationItem entity configuration
        builder.Entity<Domain.Entities.QuotationItem>(entity =>
        {
            entity.ToTable("quotation_item");
            entity.HasKey(i => i.Id);
            entity.Property(i => i.BusinessId).IsRequired();
            entity.Property(i => i.Description).HasMaxLength(300).IsRequired();
            entity.Property(i => i.Quantity).HasPrecision(18, 3);
            entity.HasIndex(i => i.QuotationId);

            entity.HasOne(i => i.Quotation)
                .WithMany(q => q.Items)
                .HasForeignKey(i => i.QuotationId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(i => i.Product)
                .WithMany()
                .HasForeignKey(i => i.ProductId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        // SyncOperation entity configuration (client idempotency key)
        builder.Entity<Domain.Entities.SyncOperation>(entity =>
        {
            entity.ToTable("sync_operation");
            entity.HasKey(o => o.Id);
            entity.Property(o => o.BusinessId).IsRequired();
            entity.Property(o => o.OperationId).HasMaxLength(64).IsRequired();
            entity.Property(o => o.EntityType).HasMaxLength(30).IsRequired();
            entity.Property(o => o.Status).HasMaxLength(20).IsRequired();
            entity.Property(o => o.Error).HasMaxLength(1000);
            entity.HasIndex(o => new { o.BusinessId, o.OperationId }).IsUnique();
            entity.HasIndex(o => new { o.BusinessId, o.Status });
        });

        // Notification entity configuration (per-user in-app feed)
        builder.Entity<Domain.Entities.Notification>(entity =>
        {
            entity.ToTable("notification");
            entity.HasKey(n => n.Id);
            entity.Property(n => n.BusinessId).IsRequired();
            entity.Property(n => n.UserId).IsRequired();
            entity.Property(n => n.Title).HasMaxLength(200).IsRequired();
            entity.Property(n => n.Body).HasMaxLength(1000).IsRequired();
            entity.Property(n => n.Category).HasMaxLength(20).HasConversion<string>();
            entity.Property(n => n.ReferenceType).HasMaxLength(30);
            entity.HasIndex(n => new { n.BusinessId, n.UserId, n.CreatedAt });
            entity.HasIndex(n => new { n.BusinessId, n.UserId, n.ReadAt });
            entity.HasIndex(n => n.DeletedAt);
        });

        // DeviceRegistration entity configuration (FCM tokens)
        builder.Entity<Domain.Entities.DeviceRegistration>(entity =>
        {
            entity.ToTable("device_registration");
            entity.HasKey(d => d.Id);
            entity.Property(d => d.BusinessId).IsRequired();
            entity.Property(d => d.UserId).IsRequired();
            entity.Property(d => d.Token).HasMaxLength(512).IsRequired();
            entity.Property(d => d.Platform).HasMaxLength(20).HasConversion<string>();
            entity.Property(d => d.IsActive).HasDefaultValue(true);
            // The token is globally unique: one physical device, one row.
            entity.HasIndex(d => d.Token).IsUnique();
            entity.HasIndex(d => new { d.BusinessId, d.UserId, d.IsActive });
        });

        // NotificationSettings entity configuration (one row per user per business)
        builder.Entity<Domain.Entities.NotificationSettings>(entity =>
        {
            entity.ToTable("notification_settings");
            entity.HasKey(s => s.Id);
            entity.Property(s => s.BusinessId).IsRequired();
            entity.Property(s => s.UserId).IsRequired();
            entity.Property(s => s.PushEnabled).HasDefaultValue(true);
            entity.Property(s => s.ReminderEnabled).HasDefaultValue(true);
            entity.Property(s => s.LowStockEnabled).HasDefaultValue(true);
            entity.Property(s => s.PaymentDueEnabled).HasDefaultValue(true);
            entity.Property(s => s.BackupEnabled).HasDefaultValue(true);
            entity.Property(s => s.SystemEnabled).HasDefaultValue(true);
            entity.HasIndex(s => new { s.BusinessId, s.UserId }).IsUnique();
        });

        // Reminder entity configuration (dated to-dos)
        builder.Entity<Domain.Entities.Reminder>(entity =>
        {
            entity.ToTable("reminder");
            entity.HasKey(r => r.Id);
            entity.Property(r => r.BusinessId).IsRequired();
            entity.Property(r => r.Title).HasMaxLength(200).IsRequired();
            entity.Property(r => r.Notes).HasMaxLength(1000);
            entity.Property(r => r.Status).HasMaxLength(20).HasConversion<string>();
            entity.Property(r => r.Repeat).HasMaxLength(20).HasConversion<string>();
            entity.Property(r => r.RelatedEntityType).HasMaxLength(30);
            entity.HasIndex(r => new { r.BusinessId, r.Status, r.DueAt });
            entity.HasIndex(r => r.DeletedAt);
        });

        // BackupRestoreEntry: the restore id ledger. One row per written row.
        builder.Entity<Domain.Entities.BackupRestoreEntry>(entity =>
        {
            entity.ToTable("backup_restore_entry");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.BusinessId).IsRequired();
            entity.Property(e => e.BackupKey).HasMaxLength(100).IsRequired();
            entity.Property(e => e.EntityType).HasMaxLength(40).IsRequired();
            // The lookup a restore performs: "have I already written this
            // payload row?" Both indexes carry the tenant, as all queries do.
            entity.HasIndex(e => new { e.BusinessId, e.BackupKey, e.EntityType, e.SourceId })
                .IsUnique();
            entity.HasIndex(e => new { e.BusinessId, e.BackupKey });
        });

        // Apply global query filters for IBusinessEntity (tenant isolation)
        ApplyBusinessEntityFilter(builder);    }

    /// <summary>
    /// Applies a global query filter on BusinessId for all entities implementing IBusinessEntity.
    /// This prevents cross-tenant data access even if a developer forgets to filter manually.
    /// </summary>
    private void ApplyBusinessEntityFilter(ModelBuilder builder)
    {
        var businessIdProp = typeof(IBusinessEntity).GetProperty(nameof(IBusinessEntity.BusinessId))!;

        foreach (var entityType in builder.Model.GetEntityTypes())
        {
            if (typeof(IBusinessEntity).IsAssignableFrom(entityType.ClrType))
            {
                var param = Expression.Parameter(entityType.ClrType, "e");
                var businessIdAccess = Expression.Property(param, businessIdProp);
                // Compare against the context's snapshotted FilterBusinessId (a property
                // read on THIS context instance). The model cache key includes that value
                // (KhataModelCacheKeyFactory), so the cached model always carries the
                // matching constant per business — no cross-business leakage.
                var currentBusinessId = Expression.Property(
                    Expression.Constant(this, typeof(KhataDbContext)),
                    nameof(FilterBusinessId));
                var equal = Expression.Equal(businessIdAccess, currentBusinessId);
                var lambda = Expression.Lambda(equal, param);

                builder.Entity(entityType.ClrType)
                    .HasQueryFilter(lambda);
            }
        }
    }

    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        EnforceImmutability();
        StampAuditFields();

        return base.SaveChangesAsync(cancellationToken);
    }

    public override int SaveChanges()
    {
        EnforceImmutability();
        StampAuditFields();

        return base.SaveChanges();
    }

    /// <summary>
    /// Append-only guarantee: IImmutable entities (stock movements, later ledger
    /// transactions) can never be updated or deleted once created.
    /// </summary>
    private void EnforceImmutability()
    {
        foreach (var entry in ChangeTracker.Entries<IImmutable>())
        {
            if (entry.State is EntityState.Modified or EntityState.Deleted)
                throw new InvalidOperationException(
                    $"{entry.Entity.GetType().Name} is immutable and cannot be modified or deleted.");
        }
    }

    private void StampAuditFields()
    {
        // Soft delete first: a `Deleted` entry is turned into a `Modified` one
        // with DeletedAt set. This must happen BEFORE the audit loop below,
        // otherwise the row is stamped as neither Added nor Modified and its
        // UpdatedAt is never touched — which would make the deletion invisible
        // to any delta sync keyed on UpdatedAt.
        foreach (var entry in ChangeTracker.Entries<ISoftDeletable>())
        {
            if (entry.State == EntityState.Deleted)
            {
                entry.State = EntityState.Modified;
                entry.Entity.DeletedAt = DateTime.UtcNow;
            }
        }

        // Auto-update audit fields
        foreach (var entry in ChangeTracker.Entries<AuditableEntity>())
        {
            switch (entry.State)
            {
                case EntityState.Added:
                    entry.Entity.CreatedAt = DateTime.UtcNow;
                    entry.Entity.UpdatedAt = DateTime.UtcNow;
                    if (_currentUserService is { UserId: var uid } && uid > 0)
                    {
                        entry.Entity.CreatedBy = uid.Value;
                        entry.Entity.UpdatedBy = uid.Value;
                    }
                    break;
                case EntityState.Modified:
                    entry.Entity.UpdatedAt = DateTime.UtcNow;
                    if (_currentUserService is { UserId: var uid2 } && uid2 > 0)
                    {
                        entry.Entity.UpdatedBy = uid2.Value;
                    }
                    break;
            }
        }

        // Immutable entities still get their creation stamps.
        foreach (var entry in ChangeTracker.Entries<Domain.Common.ImmutableEntity>())
        {
            if (entry.State == EntityState.Added)
            {
                entry.Entity.CreatedAt = DateTime.UtcNow;
                if (_currentUserService is { UserId: var uid3 } && uid3 > 0)
                {
                    entry.Entity.CreatedBy = uid3.Value;
                }
            }
        }
    }
}
