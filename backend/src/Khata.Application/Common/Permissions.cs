namespace Khata.Application.Common;

/// <summary>
/// Permission codes seeded at startup. These double as authorization policy
/// names in the API layer: [Authorize(Policy = Permissions.SettingsManage)].
/// </summary>
public static class Permissions
{
    public const string SalesView = "sales.view";
    public const string SalesCreate = "sales.create";
    public const string SalesEdit = "sales.edit";
    public const string SalesDelete = "sales.delete";
    public const string PurchaseView = "purchase.view";
    public const string PurchaseCreate = "purchase.create";
    public const string PurchaseEdit = "purchase.edit";
    public const string PurchaseDelete = "purchase.delete";
    public const string InventoryView = "inventory.view";
    public const string InventoryCreate = "inventory.create";
    public const string InventoryAdjust = "inventory.adjust";
    public const string ProductsView = "products.view";
    public const string ProductsCreate = "products.create";
    public const string ProductsEdit = "products.edit";
    public const string CustomersView = "customers.view";
    public const string CustomersCreate = "customers.create";
    public const string CustomersEdit = "customers.edit";
    public const string SuppliersView = "suppliers.view";
    public const string SuppliersCreate = "suppliers.create";
    public const string SuppliersEdit = "suppliers.edit";
    public const string ExpensesView = "expenses.view";
    public const string ExpensesCreate = "expenses.create";
    public const string ExpensesEdit = "expenses.edit";
    public const string IncomeView = "income.view";
    public const string IncomeCreate = "income.create";
    public const string IncomeEdit = "income.edit";
    public const string PaymentsView = "payments.view";
    public const string PaymentsCreate = "payments.create";
    public const string PaymentMethodsView = "payment_methods.view";
    public const string PaymentMethodsManage = "payment_methods.manage";
    public const string InvoicesView = "invoices.view";
    public const string InvoicesCreate = "invoices.create";
    public const string InvoicesEdit = "invoices.edit";
    public const string QuotationsView = "quotations.view";
    public const string QuotationsCreate = "quotations.create";
    public const string QuotationsEdit = "quotations.edit";
    public const string ReportsView = "reports.view";
    public const string ReportsExport = "reports.export";
    public const string SyncView = "sync.view";
    public const string SyncUse = "sync.use";
    public const string KhataView = "khata.view";
    public const string SettingsManage = "settings.manage";
    public const string NotificationsView = "notifications.view";
    public const string NotificationsManage = "notifications.manage";
    public const string RemindersView = "reminders.view";
    public const string RemindersManage = "reminders.manage";
    public const string BackupView = "backup.view";
    public const string BackupManage = "backup.manage";
    public const string ImportProducts = "import.products";
    public const string ImportCustomers = "import.customers";

    /// <summary>
    /// Platform administration: the /api/admin surface (cross-tenant user and
    /// business management, platform statistics, audit log, feature flags,
    /// support tickets). Granted to the platform SuperAdmin role only — it is
    /// NOT part of any business role, so no tenant user can reach it.
    /// </summary>
    public const string AdminAccess = "admin.access";

    /// <summary>Seed list: (code, description, category).</summary>
    public static readonly IReadOnlyList<(string Code, string Description, string Category)> All =
    [
        (SalesView, "View sales", "sales"),
        (SalesCreate, "Create sales", "sales"),
        (SalesEdit, "Edit sales", "sales"),
        (SalesDelete, "Delete sales", "sales"),
        (PurchaseView, "View purchases", "purchase"),
        (PurchaseCreate, "Create purchases", "purchase"),
        (PurchaseEdit, "Edit purchases", "purchase"),
        (PurchaseDelete, "Delete purchases", "purchase"),
        (InventoryView, "View inventory", "inventory"),
        (InventoryCreate, "Add products", "inventory"),
        (InventoryAdjust, "Adjust stock", "inventory"),
        (ProductsView, "View products", "inventory"),
        (ProductsCreate, "Create products", "inventory"),
        (ProductsEdit, "Edit products", "inventory"),
        (CustomersView, "View customers", "customers"),
        (CustomersCreate, "Create customers", "customers"),
        (CustomersEdit, "Edit customers", "customers"),
        (SuppliersView, "View suppliers", "suppliers"),
        (SuppliersCreate, "Create suppliers", "suppliers"),
        (SuppliersEdit, "Edit suppliers", "suppliers"),
        (ExpensesView, "View expenses", "expenses"),
        (ExpensesCreate, "Create expenses", "expenses"),
        (ExpensesEdit, "Edit expenses", "expenses"),
        (IncomeView, "View income", "income"),
        (IncomeCreate, "Create income", "income"),
        (IncomeEdit, "Edit income", "income"),
        (PaymentsView, "View payments", "payments"),
        (PaymentsCreate, "Record payments", "payments"),
        (PaymentMethodsView, "View payment methods", "payments"),
        (PaymentMethodsManage, "Manage payment methods", "payments"),
        (InvoicesView, "View invoices", "invoices"),
        (InvoicesCreate, "Create invoices", "invoices"),
        (InvoicesEdit, "Edit invoices", "invoices"),
        (QuotationsView, "View quotations", "quotations"),
        (QuotationsCreate, "Create quotations", "quotations"),
        (QuotationsEdit, "Edit quotations", "quotations"),
        (ReportsView, "View reports", "reports"),
        (ReportsExport, "Export reports", "reports"),
        (SyncView, "View sync status", "sync"),
        (SyncUse, "Synchronise data", "sync"),
        (KhataView, "View ledger", "khata"),
        (SettingsManage, "Manage settings", "settings"),
        (NotificationsView, "View notifications", "notifications"),
        (NotificationsManage, "Manage notifications", "notifications"),
        (RemindersView, "View reminders", "reminders"),
        (RemindersManage, "Manage reminders", "reminders"),
        (BackupView, "Export business data", "backup"),
        (BackupManage, "Restore business data", "backup"),
        (ImportProducts, "Import products from CSV", "import"),
        (ImportCustomers, "Import customers from CSV", "import"),
        (AdminAccess, "Platform administration", "admin"),
    ];
}
