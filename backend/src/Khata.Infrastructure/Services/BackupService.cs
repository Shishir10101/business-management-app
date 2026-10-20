namespace Khata.Infrastructure.Services;

using Khata.Application.DTOs;
using Khata.Application.Interfaces;
using Khata.Domain.Common;
using Khata.Domain.Entities;
using Khata.Domain.Exceptions;
using Khata.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

/// <summary>
/// Business data backup. Export produces a full JSON snapshot of the active
/// business (including soft-deleted rows, so history survives); restore
/// inserts rows that do not exist yet, keeping their original ids.
/// </summary>
/// <remarks>
/// Restore is a MERGE, never an overwrite. Rows whose id already exists in the
/// target business are skipped: money rows (sales, purchases, payments) are
/// immutable by design, so rewriting them would silently corrupt the khata
/// ledger and stock caches. Restoring into a fresh business reproduces the
/// snapshot exactly.
///
/// Ledger accounts/transactions and stock movements are deliberately NOT part
/// of the payload: they are derived ledgers. Restoring the documents without
/// their derived entries would produce a dataset whose caches and ledgers
/// disagree, which is worse than not restoring them at all. Backups therefore
/// restore the *documents*; the derived ledgers are rebuilt by replaying the
/// business operations, not by a file copy.
/// </remarks>
public class BackupService : IBackupService
{
    public const int CurrentVersion = 1;

    private readonly KhataDbContext _db;
    private readonly ICurrentUserService _currentUser;
    private readonly IDateTimeProvider _clock;

    public BackupService(KhataDbContext db, ICurrentUserService currentUser, IDateTimeProvider clock)
    {
        _db = db;
        _currentUser = currentUser;
        _clock = clock;
    }

    private long BusinessId =>
        _currentUser.BusinessId ?? throw new UnauthorizedException();

    public async Task<BackupExportDto> ExportAsync(CancellationToken cancellationToken = default)
    {
        var businessId = BusinessId;

        var business = await _db.Businesses
            .FirstOrDefaultAsync(b => b.Id == businessId, cancellationToken)
            ?? throw new NotFoundException("Business", businessId);

        // Soft-deleted rows are included on purpose: a restore must reproduce
        // the dataset, including what was removed and when.
        var products = await _db.Products
            .Where(p => p.BusinessId == businessId)
            .OrderBy(p => p.Id)
            .ToListAsync(cancellationToken);

        var stocks = await _db.ProductStocks
            .Where(s => s.BusinessId == businessId)
            .ToDictionaryAsync(s => s.ProductId, cancellationToken);

        var categories = await _db.ProductCategories
            .Where(c => c.BusinessId == businessId).OrderBy(c => c.Id)
            .ToListAsync(cancellationToken);

        var units = await _db.Units
            .Where(u => u.BusinessId == businessId).OrderBy(u => u.Id)
            .ToListAsync(cancellationToken);

        var customers = await _db.Customers
            .Where(c => c.BusinessId == businessId).OrderBy(c => c.Id)
            .ToListAsync(cancellationToken);

        var suppliers = await _db.Suppliers
            .Where(s => s.BusinessId == businessId).OrderBy(s => s.Id)
            .ToListAsync(cancellationToken);

        var sales = await _db.Sales
            .Where(s => s.BusinessId == businessId)
            .Include(s => s.Items)
            .OrderBy(s => s.Id)
            .ToListAsync(cancellationToken);

        var purchases = await _db.Purchases
            .Where(p => p.BusinessId == businessId)
            .Include(p => p.Items)
            .OrderBy(p => p.Id)
            .ToListAsync(cancellationToken);

        var expenses = await _db.Expenses
            .Where(e => e.BusinessId == businessId).OrderBy(e => e.Id)
            .ToListAsync(cancellationToken);

        var incomes = await _db.Incomes
            .Where(i => i.BusinessId == businessId).OrderBy(i => i.Id)
            .ToListAsync(cancellationToken);

        var payments = await _db.Payments
            .Where(p => p.BusinessId == businessId).OrderBy(p => p.Id)
            .ToListAsync(cancellationToken);

        var methods = await _db.PaymentMethods
            .Where(m => m.BusinessId == businessId).OrderBy(m => m.Id)
            .ToListAsync(cancellationToken);

        var invoices = await _db.Invoices
            .Where(i => i.BusinessId == businessId)
            .Include(i => i.Items)
            .OrderBy(i => i.Id)
            .ToListAsync(cancellationToken);

        var quotations = await _db.Quotations
            .Where(q => q.BusinessId == businessId)
            .Include(q => q.Items)
            .OrderBy(q => q.Id)
            .ToListAsync(cancellationToken);

        return new BackupExportDto(
            Version: CurrentVersion,
            BusinessId: businessId,
            BusinessName: business.Name,
            ExportedAt: _clock.UtcNow,
            Products: products.Select(p => new BackupProduct(
                p.Id, p.CategoryId, p.UnitId, p.Name, p.Sku, p.Barcode, p.Description,
                p.CostPrice, p.SellingPrice, p.WholesalePrice, p.TaxRateBps, p.ImageUrl,
                p.IsActive,
                stocks.TryGetValue(p.Id, out var stock) ? stock.Quantity : 0m,
                stocks.TryGetValue(p.Id, out var s2) ? s2.MinQuantity : 0m,
                p.DeletedAt)).ToList(),
            Categories: categories.Select(c => new BackupCategory(
                c.Id, c.Name, c.Description, c.ParentId, c.IsActive, c.DeletedAt)).ToList(),
            Units: units.Select(u => new BackupUnit(
                u.Id, u.Name, u.ShortName, u.IsActive, u.DeletedAt)).ToList(),
            Customers: customers.Select(c => new BackupCustomer(
                c.Id, c.Name, c.PhoneNumber, c.Email, c.AddressLine, c.City, c.District,
                c.OpeningBalance, c.PanNumber, c.CreditLimit, c.Notes, c.IsActive,
                c.DeletedAt)).ToList(),
            Suppliers: suppliers.Select(s => new BackupSupplier(
                s.Id, s.Name, s.PhoneNumber, s.Email, s.AddressLine, s.City, s.District,
                s.OpeningBalance, s.PanNumber, s.Notes, s.IsActive, s.DeletedAt)).ToList(),
            Sales: sales.Select(s => new BackupSale(
                s.Id, s.InvoiceNumber, s.CustomerId, s.SaleType, s.PaymentStatus, s.SaleDate,
                s.Subtotal, s.DiscountAmount, s.TaxAmount, s.TotalAmount, s.PaidAmount,
                s.DueAmount, s.Notes,
                s.Items.Select(i => new BackupSaleItem(
                    i.Id, i.ProductId, i.ProductName, i.Quantity, i.UnitPrice,
                    i.DiscountAmount, i.TaxRateBps, i.TaxAmount, i.LineTotal)).ToList(),
                s.DeletedAt)).ToList(),
            Purchases: purchases.Select(p => new BackupPurchase(
                p.Id, p.BillNumber, p.SupplierId, p.PurchaseType, p.PaymentStatus,
                p.PurchaseDate, p.Subtotal, p.DiscountAmount, p.TaxAmount, p.TotalAmount,
                p.PaidAmount, p.DueAmount, p.Notes,
                p.Items.Select(i => new BackupPurchaseItem(
                    i.Id, i.ProductId, i.ProductName, i.Quantity, i.UnitPrice,
                    i.DiscountAmount, i.TaxRateBps, i.TaxAmount, i.LineTotal)).ToList(),
                p.DeletedAt)).ToList(),
            Expenses: expenses.Select(e => new BackupExpense(
                e.Id, e.Category, e.Amount, e.ExpenseDate, e.Description, e.PaymentMethod,
                e.Reference, e.Notes, e.DeletedAt)).ToList(),
            Incomes: incomes.Select(i => new BackupIncome(
                i.Id, i.Source, i.Amount, i.IncomeDate, i.Description, i.PaymentMethod,
                i.Reference, i.Notes, i.DeletedAt)).ToList(),
            Payments: payments.Select(p => new BackupPayment(
                p.Id, p.PartyType, p.PartyId, p.Direction, p.Amount, p.PaymentDate,
                p.PaymentMethodId, p.MethodName, p.Reference, p.Notes, p.SaleId,
                p.PurchaseId, p.AppliedAmount, p.UnappliedAmount)).ToList(),
            PaymentMethods: methods.Select(m => new BackupPaymentMethod(
                m.Id, m.Name, m.Code, m.Description, m.IsActive, m.IsDefault,
                m.DeletedAt)).ToList(),
            Invoices: invoices.Select(i => new BackupInvoice(
                i.Id, i.InvoiceNumber, i.CustomerId, i.SaleId, i.Status, i.IssueDate,
                i.DueDate, i.Subtotal, i.DiscountAmount, i.TaxAmount, i.TotalAmount,
                i.Notes, i.Terms, i.PdfPath, i.PdfGeneratedAt,
                i.Items.Select(x => new BackupInvoiceItem(
                    x.Id, x.ProductId, x.Description, x.Quantity, x.UnitPrice,
                    x.DiscountAmount, x.TaxRateBps, x.TaxAmount, x.LineTotal)).ToList(),
                i.DeletedAt)).ToList(),
            Quotations: quotations.Select(q => new BackupQuotation(
                q.Id, q.QuoteNumber, q.CustomerId, q.Status, q.IssueDate, q.ValidUntil,
                q.Subtotal, q.DiscountAmount, q.TaxAmount, q.TotalAmount, q.Notes,
                q.Terms, q.ConvertedSaleId, q.PdfPath, q.PdfGeneratedAt,
                q.Items.Select(x => new BackupQuotationItem(
                    x.Id, x.ProductId, x.Description, x.Quantity, x.UnitPrice,
                    x.DiscountAmount, x.TaxRateBps, x.TaxAmount, x.LineTotal)).ToList(),
                q.DeletedAt)).ToList());
    }

    public async Task<BackupRestoreResultDto> RestoreAsync(
        BackupExportDto backup, CancellationToken cancellationToken = default)
    {
        var businessId = BusinessId;

        if (backup is null)
            throw new ValidationException(new Dictionary<string, string[]>
            {
                ["backup"] = ["A backup payload is required."],
            });
        if (backup.Version > CurrentVersion)
            throw new ValidationException(new Dictionary<string, string[]>
            {
                ["version"] = [$"Backup version {backup.Version} is newer than this server ({CurrentVersion})."],
            });

        // The id ledger written by earlier restores of this same file. It is
        // the primary guard: it survives id re-homing and local edits, both of
        // which defeat a plain "does this id exist" check. See
        // BackupRestoreEntry for why ids alone cannot answer the question.
        var backupKey = BackupKeyFor(backup);
        var ledger = await _db.BackupRestoreEntries
            .Where(e => e.BusinessId == businessId && e.BackupKey == backupKey)
            .ToListAsync(cancellationToken);
        var restored = ledger
            .GroupBy(e => e.EntityType, StringComparer.Ordinal)
            .ToDictionary(
                g => g.Key,
                g => g.ToDictionary(e => e.SourceId, e => e.TargetId),
                StringComparer.Ordinal);

        // Two id sets are needed, and they answer different questions:
        //
        //  * Ids OWNED by the target business  -> the row is already here, so
        //    the payload entry is skipped (merge, never overwrite). This is the
        //    idempotency contract, and it holds whether the row was written by
        //    an earlier restore or by the user.
        //  * Ids owned by ANYONE at all        -> the value is taken, so it
        //    cannot be inserted verbatim (primary keys are global). The row is
        //    still inserted, but under a freshly allocated id, and every
        //    reference to it is remapped.
        //
        // The second case is real: one database can hold several businesses
        // (the shared test fixture, or a consolidated server), and a backup
        // taken from business A carries A's ids. Restoring A's snapshot into B
        // must not fail on the collision, and must not skip the data either.
        var existing = new ExistingIds
        {
            Units = await BusinessIdsAsync(_db.Units, businessId, cancellationToken),
            Categories = await BusinessIdsAsync(_db.ProductCategories, businessId, cancellationToken),
            Products = await BusinessIdsAsync(_db.Products, businessId, cancellationToken),
            Customers = await BusinessIdsAsync(_db.Customers, businessId, cancellationToken),
            Suppliers = await BusinessIdsAsync(_db.Suppliers, businessId, cancellationToken),
            Methods = await BusinessIdsAsync(_db.PaymentMethods, businessId, cancellationToken),
            Sales = await BusinessIdsAsync(_db.Sales, businessId, cancellationToken),
            Purchases = await BusinessIdsAsync(_db.Purchases, businessId, cancellationToken),
            Expenses = await BusinessIdsAsync(_db.Expenses, businessId, cancellationToken),
            Incomes = await BusinessIdsAsync(_db.Incomes, businessId, cancellationToken),
            Payments = await BusinessIdsAsync(_db.Payments, businessId, cancellationToken),
            Invoices = await BusinessIdsAsync(_db.Invoices, businessId, cancellationToken),
            Quotations = await BusinessIdsAsync(_db.Quotations, businessId, cancellationToken),
        };

        var taken = new TakenIds
        {
            Units = await AllIdsAsync(_db.Units, cancellationToken),
            Categories = await AllIdsAsync(_db.ProductCategories, cancellationToken),
            Products = await AllIdsAsync(_db.Products, cancellationToken),
            Customers = await AllIdsAsync(_db.Customers, cancellationToken),
            Suppliers = await AllIdsAsync(_db.Suppliers, cancellationToken),
            Methods = await AllIdsAsync(_db.PaymentMethods, cancellationToken),
            Sales = await AllIdsAsync(_db.Sales, cancellationToken),
            Purchases = await AllIdsAsync(_db.Purchases, cancellationToken),
            Expenses = await AllIdsAsync(_db.Expenses, cancellationToken),
            Incomes = await AllIdsAsync(_db.Incomes, cancellationToken),
            Payments = await AllIdsAsync(_db.Payments, cancellationToken),
            Invoices = await AllIdsAsync(_db.Invoices, cancellationToken),
            Quotations = await AllIdsAsync(_db.Quotations, cancellationToken),
        };

        // Payload id -> id actually written, for every table. A table that is
        // not remapped maps each id to itself, so references can be rewritten
        // unconditionally. Seeded from the ledger so references inside a
        // repeated restore still resolve to the rows the first one wrote.
        var map = RestoreIdMap.FromLedger(restored);

        var counts = new RestoreCounts();

        // Order matters: parents before children, so foreign keys resolve.
        RestoreUnits(backup, businessId, existing, taken, map, counts, restored);
        RestoreCategories(backup, businessId, existing, taken, map, counts, restored);
        RestoreProducts(backup, businessId, existing, taken, map, counts, restored);
        RestoreCustomers(backup, businessId, existing, taken, map, counts, restored);
        RestoreSuppliers(backup, businessId, existing, taken, map, counts, restored);
        RestoreMethods(backup, businessId, existing, taken, map, counts, restored);

        // Save the basics first so document FK lookups below see them.
        await _db.SaveChangesAsync(cancellationToken);

        RestoreSales(backup, businessId, existing, taken, map, counts, restored);
        RestorePurchases(backup, businessId, existing, taken, map, counts, restored);
        RestoreExpenses(backup, businessId, existing, taken, map, counts, restored);
        RestoreIncomes(backup, businessId, existing, taken, map, counts, restored);
        RestoreInvoices(backup, businessId, existing, taken, map, counts, restored);
        RestoreQuotations(backup, businessId, existing, taken, map, counts, restored);

        await _db.SaveChangesAsync(cancellationToken);

        // Payments last: they reference sales/purchases inserted above.
        RestorePayments(backup, businessId, existing, taken, map, counts, restored);

        // Record what was written so the next restore of this file recognises
        // these rows. Only rows that were actually inserted are recorded: a row
        // that was skipped already has a ledger entry (or is the user's own).
        foreach (var (entityType, entries) in map.Pairs)
        {
            foreach (var (sourceId, targetId) in entries)
            {
                if (!WasWrittenThisRun(entityType, sourceId, restored)) continue;

                _db.BackupRestoreEntries.Add(new BackupRestoreEntry
                {
                    BusinessId = businessId,
                    BackupKey = backupKey,
                    EntityType = entityType,
                    SourceId = sourceId,
                    TargetId = targetId,
                });
            }
        }

        await _db.SaveChangesAsync(cancellationToken);

        return new BackupRestoreResultDto(
            businessId,
            counts.ProductsInserted, counts.ProductsSkipped,
            counts.CustomersInserted, counts.CustomersSkipped,
            counts.SuppliersInserted, counts.SuppliersSkipped,
            counts.SalesInserted, counts.SalesSkipped,
            counts.PurchasesInserted, counts.PurchasesSkipped,
            counts.ExpensesInserted, counts.ExpensesSkipped,
            counts.IncomesInserted, counts.IncomesSkipped,
            counts.PaymentsInserted, counts.PaymentsSkipped,
            counts.InvoicesInserted, counts.InvoicesSkipped,
            counts.QuotationsInserted, counts.QuotationsSkipped,
            counts.PaymentMethodsInserted, counts.PaymentMethodsMatched,
            counts.UnitsInserted, counts.UnitsMatched);
    }

    // ---------------------------------------------------------------
    // Per-table restore
    // ---------------------------------------------------------------

    private void RestoreUnits(BackupExportDto backup, long businessId, ExistingIds existing,
        TakenIds taken, RestoreIdMap map, RestoreCounts counts,
        Dictionary<string, Dictionary<long, long>> restored)
    {
        // Units are a seeded lookup with a unique (BusinessId, Name): match an
        // existing unit by name and reuse it rather than inserting a duplicate.
        var byName = _db.Units
            .Where(u => u.BusinessId == businessId)
            .ToDictionary(u => u.Name, u => u.Id, StringComparer.OrdinalIgnoreCase);

        foreach (var u in backup.Units)
        {
            if (AlreadyRestored(restored, EntityTypes.Unit, u.Id)) continue;
            if (!existing.Units.Add(u.Id)) continue;

            if (byName.TryGetValue(u.Name, out var matchId))
            {
                map.Units[u.Id] = matchId;
                counts.UnitsMatched++;
                continue;
            }

            var id = taken.NextUnit(u.Id);
            map.Units[u.Id] = id;
            byName[u.Name] = id;
            _db.Units.Add(new Unit
            {
                Id = id,
                BusinessId = businessId,
                Name = u.Name,
                ShortName = u.ShortName,
                IsActive = u.IsActive,
                DeletedAt = u.DeletedAt,
            });
            counts.UnitsInserted++;
        }
    }

    private void RestoreCategories(BackupExportDto backup, long businessId, ExistingIds existing,
        TakenIds taken, RestoreIdMap map, RestoreCounts counts,
        Dictionary<string, Dictionary<long, long>> restored)
    {
        // Ids are allocated up front so a child can reference its parent even if
        // the parent appears later in the payload. Categories already written
        // by an earlier restore of this file are dropped here.
        var pending = backup.Categories
            .Where(c => !AlreadyRestored(restored, EntityTypes.Category, c.Id))
            .Where(c => existing.Categories.Add(c.Id))
            .ToList();
        foreach (var c in pending)
        {
            map.Categories[c.Id] = taken.NextCategory(c.Id);
        }

        var done = new HashSet<long>();

        for (var pass = 0; pass < 2 && pending.Count > 0; pass++)
        {
            foreach (var c in pending.ToList())
            {
                if (c.ParentId is { } parentId && parentId != 0 && !done.Contains(parentId))
                    continue; // wait for the parent

                _db.ProductCategories.Add(new ProductCategory
                {
                    Id = map.Categories[c.Id],
                    BusinessId = businessId,
                    Name = c.Name,
                    Description = c.Description,
                    ParentId = c.ParentId is { } p && map.Categories.TryGetValue(p, out var newParent)
                        ? newParent
                        : c.ParentId,
                    IsActive = c.IsActive,
                    DeletedAt = c.DeletedAt,
                });
                done.Add(c.Id);
                pending.Remove(c);
            }
        }

        // Any leftovers had a parent that does not exist in the payload;
        // insert them rootless rather than dropping them.
        foreach (var c in pending)
        {
            _db.ProductCategories.Add(new ProductCategory
            {
                Id = map.Categories[c.Id],
                BusinessId = businessId,
                Name = c.Name,
                Description = c.Description,
                ParentId = null,
                IsActive = c.IsActive,
                DeletedAt = c.DeletedAt,
            });
        }
    }

    private void RestoreProducts(BackupExportDto backup, long businessId, ExistingIds existing,
        TakenIds taken, RestoreIdMap map, RestoreCounts counts,
        Dictionary<string, Dictionary<long, long>> restored)
    {
        // A product's name is unique enough to identify it within one business
        // (there is no DB constraint, but two products sharing a name in a
        // khata would be indistinguishable to the shopkeeper). Matching on it
        // keeps a repeated restore idempotent even after the first pass had to
        // re-home the row onto a free id, and prevents duplicating the
        // catalogue when the snapshot is restored over live data.
        var byName = _db.Products
            .Where(p => p.BusinessId == businessId)
            .ToDictionary(p => p.Name, p => p.Id, StringComparer.OrdinalIgnoreCase);

        foreach (var p in backup.Products)
        {
            if (AlreadyRestored(restored, EntityTypes.Product, p.Id))
            {
                counts.ProductsSkipped++;
                continue;
            }
            if (!existing.Products.Add(p.Id) || byName.TryGetValue(p.Name, out var matchId))
            {
                if (byName.TryGetValue(p.Name, out var existingId)) map.Products[p.Id] = existingId;
                counts.ProductsSkipped++;
                continue;
            }

            var id = taken.NextProduct(p.Id);
            map.Products[p.Id] = id;
            byName[p.Name] = id;
            _db.Products.Add(new Product
            {
                Id = id,
                BusinessId = businessId,
                CategoryId = Remap(map.Categories, p.CategoryId),
                UnitId = Remap(map.Units, p.UnitId),
                Name = p.Name,
                Sku = p.Sku,
                Barcode = p.Barcode,
                Description = p.Description,
                CostPrice = p.CostPrice,
                SellingPrice = p.SellingPrice,
                WholesalePrice = p.WholesalePrice,
                TaxRateBps = p.TaxRateBps,
                ImageUrl = p.ImageUrl,
                IsActive = p.IsActive,
                DeletedAt = p.DeletedAt,
                Stock = new ProductStock
                {
                    BusinessId = businessId,
                    ProductId = id,
                    Quantity = p.StockQuantity,
                    MinQuantity = p.MinQuantity,
                },
            });
            counts.ProductsInserted++;
        }
    }

    private void RestoreCustomers(BackupExportDto backup, long businessId, ExistingIds existing,
        TakenIds taken, RestoreIdMap map, RestoreCounts counts,
        Dictionary<string, Dictionary<long, long>> restored)
    {
        // Matched by name within the business, for the same reason as products:
        // one customer name means one customer, so a repeated restore neither
        // duplicates the party nor creates a second ledger account for it.
        var byName = _db.Customers
            .Where(c => c.BusinessId == businessId)
            .ToDictionary(c => c.Name, c => c.Id, StringComparer.OrdinalIgnoreCase);

        foreach (var c in backup.Customers)
        {
            if (AlreadyRestored(restored, EntityTypes.Customer, c.Id))
            {
                counts.CustomersSkipped++;
                continue;
            }
            if (!existing.Customers.Add(c.Id) || byName.ContainsKey(c.Name))
            {
                if (byName.TryGetValue(c.Name, out var existingId)) map.Customers[c.Id] = existingId;
                counts.CustomersSkipped++;
                continue;
            }

            var id = taken.NextCustomer(c.Id);
            map.Customers[c.Id] = id;
            byName[c.Name] = id;
            _db.Customers.Add(new Customer
            {
                Id = id,
                BusinessId = businessId,
                Name = c.Name,
                PhoneNumber = c.PhoneNumber,
                Email = c.Email,
                AddressLine = c.AddressLine,
                City = c.City,
                District = c.District,
                OpeningBalance = c.OpeningBalance,
                PanNumber = c.PanNumber,
                CreditLimit = c.CreditLimit,
                Notes = c.Notes,
                IsActive = c.IsActive,
                DeletedAt = c.DeletedAt,
            });
            counts.CustomersInserted++;
        }
    }

    private void RestoreSuppliers(BackupExportDto backup, long businessId, ExistingIds existing,
        TakenIds taken, RestoreIdMap map, RestoreCounts counts,
        Dictionary<string, Dictionary<long, long>> restored)
    {
        // Matched by name within the business: see RestoreCustomers.
        var byName = _db.Suppliers
            .Where(s => s.BusinessId == businessId)
            .ToDictionary(s => s.Name, s => s.Id, StringComparer.OrdinalIgnoreCase);

        foreach (var s in backup.Suppliers)
        {
            if (AlreadyRestored(restored, EntityTypes.Supplier, s.Id))
            {
                counts.SuppliersSkipped++;
                continue;
            }
            if (!existing.Suppliers.Add(s.Id) || byName.ContainsKey(s.Name))
            {
                if (byName.TryGetValue(s.Name, out var existingId)) map.Suppliers[s.Id] = existingId;
                counts.SuppliersSkipped++;
                continue;
            }

            var id = taken.NextSupplier(s.Id);
            map.Suppliers[s.Id] = id;
            byName[s.Name] = id;
            _db.Suppliers.Add(new Supplier
            {
                Id = id,
                BusinessId = businessId,
                Name = s.Name,
                PhoneNumber = s.PhoneNumber,
                Email = s.Email,
                AddressLine = s.AddressLine,
                City = s.City,
                District = s.District,
                OpeningBalance = s.OpeningBalance,
                PanNumber = s.PanNumber,
                Notes = s.Notes,
                IsActive = s.IsActive,
                DeletedAt = s.DeletedAt,
            });
            counts.SuppliersInserted++;
        }
    }

    private void RestoreMethods(BackupExportDto backup, long businessId, ExistingIds existing,
        TakenIds taken, RestoreIdMap map, RestoreCounts counts,
        Dictionary<string, Dictionary<long, long>> restored)
    {
        // Payment methods are lookups, not documents: their name is unique per
        // business, and every business is seeded with a default set. A restore
        // therefore MATCHES BY NAME first — reusing the target's existing
        // method and remapping payments onto it — and only inserts methods the
        // target genuinely lacks. Skipping this step collides on
        // (BusinessId, Name) and fails the whole restore.
        var byName = _db.PaymentMethods
            .Where(m => m.BusinessId == businessId)
            .ToDictionary(m => m.Name, m => m.Id, StringComparer.OrdinalIgnoreCase);

        foreach (var m in backup.PaymentMethods)
        {
            if (AlreadyRestored(restored, EntityTypes.PaymentMethod, m.Id)) continue;
            if (!existing.Methods.Add(m.Id)) continue;

            if (byName.TryGetValue(m.Name, out var matchId))
            {
                // Present already: point references at the row that is here.
                map.Methods[m.Id] = matchId;
                counts.PaymentMethodsMatched++;
                continue;
            }

            var id = taken.NextMethod(m.Id);
            map.Methods[m.Id] = id;
            byName[m.Name] = id;
            _db.PaymentMethods.Add(new PaymentMethod
            {
                Id = id,
                BusinessId = businessId,
                Name = m.Name,
                Code = m.Code,
                Description = m.Description,
                IsActive = m.IsActive,
                IsDefault = m.IsDefault,
                DeletedAt = m.DeletedAt,
            });
            counts.PaymentMethodsInserted++;
        }
    }

    private void RestoreSales(BackupExportDto backup, long businessId, ExistingIds existing,
        TakenIds taken, RestoreIdMap map, RestoreCounts counts,
        Dictionary<string, Dictionary<long, long>> restored)
    {
        // The invoice number is unique per business and is the document's
        // natural key: if the target already issued it, the document is here —
        // skip, whatever id it ended up with. This is also what makes a second
        // restore idempotent when the first one had to re-home the row onto a
        // free id.
        var numbers = _db.Sales
            .Where(s => s.BusinessId == businessId)
            .Select(s => s.InvoiceNumber)
            .ToHashSet(StringComparer.OrdinalIgnoreCase);

        foreach (var s in backup.Sales)
        {
            if (AlreadyRestored(restored, EntityTypes.Sale, s.Id))
            {
                counts.SalesSkipped++;
                continue;
            }
            if (!existing.Sales.Add(s.Id) || numbers.Contains(s.InvoiceNumber))
            {
                counts.SalesSkipped++;
                continue;
            }
            numbers.Add(s.InvoiceNumber);

            var id = taken.NextSale(s.Id);
            map.Sales[s.Id] = id;
            var sale = new Sale
            {
                Id = id,
                BusinessId = businessId,
                InvoiceNumber = s.InvoiceNumber,
                CustomerId = Remap(map.Customers, s.CustomerId),
                SaleType = s.SaleType,
                PaymentStatus = s.PaymentStatus,
                SaleDate = s.SaleDate,
                Subtotal = s.Subtotal,
                DiscountAmount = s.DiscountAmount,
                TaxAmount = s.TaxAmount,
                TotalAmount = s.TotalAmount,
                PaidAmount = s.PaidAmount,
                DueAmount = s.DueAmount,
                Notes = s.Notes,
                DeletedAt = s.DeletedAt,
                Items = s.Items.Select(i => new SaleItem
                {
                    BusinessId = businessId,
                    SaleId = id,
                    ProductId = Remap(map.Products, i.ProductId),
                    ProductName = i.ProductName,
                    Quantity = i.Quantity,
                    UnitPrice = i.UnitPrice,
                    DiscountAmount = i.DiscountAmount,
                    TaxRateBps = i.TaxRateBps,
                    TaxAmount = i.TaxAmount,
                    LineTotal = i.LineTotal,
                }).ToList(),
            };

            _db.Sales.Add(sale);
            counts.SalesInserted++;
        }
    }

    private void RestorePurchases(BackupExportDto backup, long businessId, ExistingIds existing,
        TakenIds taken, RestoreIdMap map, RestoreCounts counts,
        Dictionary<string, Dictionary<long, long>> restored)
    {
        // The bill number is unique per business: see RestoreSales for why the
        // natural key, not just the id, guards the merge.
        var numbers = _db.Purchases
            .Where(p => p.BusinessId == businessId)
            .Select(p => p.BillNumber)
            .ToHashSet(StringComparer.OrdinalIgnoreCase);

        foreach (var p in backup.Purchases)
        {
            if (AlreadyRestored(restored, EntityTypes.Purchase, p.Id))
            {
                counts.PurchasesSkipped++;
                continue;
            }
            if (!existing.Purchases.Add(p.Id) || numbers.Contains(p.BillNumber))
            {
                counts.PurchasesSkipped++;
                continue;
            }
            numbers.Add(p.BillNumber);

            var id = taken.NextPurchase(p.Id);
            map.Purchases[p.Id] = id;
            _db.Purchases.Add(new Purchase
            {
                Id = id,
                BusinessId = businessId,
                BillNumber = p.BillNumber,
                SupplierId = Remap(map.Suppliers, p.SupplierId),
                PurchaseType = p.PurchaseType,
                PaymentStatus = p.PaymentStatus,
                PurchaseDate = p.PurchaseDate,
                Subtotal = p.Subtotal,
                DiscountAmount = p.DiscountAmount,
                TaxAmount = p.TaxAmount,
                TotalAmount = p.TotalAmount,
                PaidAmount = p.PaidAmount,
                DueAmount = p.DueAmount,
                Notes = p.Notes,
                DeletedAt = p.DeletedAt,
                Items = p.Items.Select(i => new PurchaseItem
                {
                    BusinessId = businessId,
                    PurchaseId = id,
                    ProductId = Remap(map.Products, i.ProductId),
                    ProductName = i.ProductName,
                    Quantity = i.Quantity,
                    UnitPrice = i.UnitPrice,
                    DiscountAmount = i.DiscountAmount,
                    TaxRateBps = i.TaxRateBps,
                    TaxAmount = i.TaxAmount,
                    LineTotal = i.LineTotal,
                }).ToList(),
            });
            counts.PurchasesInserted++;
        }
    }

    private void RestoreExpenses(BackupExportDto backup, long businessId, ExistingIds existing,
        TakenIds taken, RestoreIdMap map, RestoreCounts counts,
        Dictionary<string, Dictionary<long, long>> restored)
    {
        foreach (var e in backup.Expenses)
        {
            if (AlreadyRestored(restored, EntityTypes.Expense, e.Id))
            {
                counts.ExpensesSkipped++;
                continue;
            }
            if (!existing.Expenses.Add(e.Id))
            {
                counts.ExpensesSkipped++;
                continue;
            }

            var id = taken.NextExpense(e.Id);
            map.Expenses[e.Id] = id;
            _db.Expenses.Add(new Expense
            {
                Id = id,
                BusinessId = businessId,
                Category = e.Category,
                Amount = e.Amount,
                ExpenseDate = e.ExpenseDate,
                Description = e.Description,
                PaymentMethod = e.PaymentMethod,
                Reference = e.Reference,
                Notes = e.Notes,
                DeletedAt = e.DeletedAt,
            });
            counts.ExpensesInserted++;
        }
    }

    private void RestoreIncomes(BackupExportDto backup, long businessId, ExistingIds existing,
        TakenIds taken, RestoreIdMap map, RestoreCounts counts,
        Dictionary<string, Dictionary<long, long>> restored)
    {
        foreach (var i in backup.Incomes)
        {
            if (AlreadyRestored(restored, EntityTypes.Income, i.Id))
            {
                counts.IncomesSkipped++;
                continue;
            }
            if (!existing.Incomes.Add(i.Id))
            {
                counts.IncomesSkipped++;
                continue;
            }

            var id = taken.NextIncome(i.Id);
            map.Incomes[i.Id] = id;
            _db.Incomes.Add(new Income
            {
                Id = id,
                BusinessId = businessId,
                Source = i.Source,
                Amount = i.Amount,
                IncomeDate = i.IncomeDate,
                Description = i.Description,
                PaymentMethod = i.PaymentMethod,
                Reference = i.Reference,
                Notes = i.Notes,
                DeletedAt = i.DeletedAt,
            });
            counts.IncomesInserted++;
        }
    }

    private void RestorePayments(BackupExportDto backup, long businessId, ExistingIds existing,
        TakenIds taken, RestoreIdMap map, RestoreCounts counts,
        Dictionary<string, Dictionary<long, long>> restored)
    {
        foreach (var p in backup.Payments)
        {
            if (AlreadyRestored(restored, EntityTypes.Payment, p.Id))
            {
                counts.PaymentsSkipped++;
                continue;
            }
            if (!existing.Payments.Add(p.Id))
            {
                counts.PaymentsSkipped++;
                continue;
            }

            _db.Payments.Add(new Payment
            {
                Id = taken.NextPayment(p.Id),
                BusinessId = businessId,
                PartyType = p.PartyType,
                PartyId = Remap(map.Parties(p.PartyType), p.PartyId),
                Direction = p.Direction,
                Amount = p.Amount,
                PaymentDate = p.PaymentDate,
                PaymentMethodId = Remap(map.Methods, p.PaymentMethodId),
                MethodName = p.MethodName,
                Reference = p.Reference,
                Notes = p.Notes,
                SaleId = Remap(map.Sales, p.SaleId),
                PurchaseId = Remap(map.Purchases, p.PurchaseId),
                AppliedAmount = p.AppliedAmount,
                UnappliedAmount = p.UnappliedAmount,
            });
            counts.PaymentsInserted++;
        }
    }

    private void RestoreInvoices(BackupExportDto backup, long businessId, ExistingIds existing,
        TakenIds taken, RestoreIdMap map, RestoreCounts counts,
        Dictionary<string, Dictionary<long, long>> restored)
    {
        // The invoice number is unique per business: see RestoreSales.
        var numbers = _db.Invoices
            .Where(i => i.BusinessId == businessId)
            .Select(i => i.InvoiceNumber)
            .ToHashSet(StringComparer.OrdinalIgnoreCase);

        foreach (var i in backup.Invoices)
        {
            if (AlreadyRestored(restored, EntityTypes.Invoice, i.Id))
            {
                counts.InvoicesSkipped++;
                continue;
            }
            if (!existing.Invoices.Add(i.Id) || numbers.Contains(i.InvoiceNumber))
            {
                counts.InvoicesSkipped++;
                continue;
            }
            numbers.Add(i.InvoiceNumber);

            var id = taken.NextInvoice(i.Id);
            map.Invoices[i.Id] = id;
            _db.Invoices.Add(new Invoice
            {
                Id = id,
                BusinessId = businessId,
                InvoiceNumber = i.InvoiceNumber,
                CustomerId = Remap(map.Customers, i.CustomerId),
                SaleId = Remap(map.Sales, i.SaleId),
                Status = i.Status,
                IssueDate = i.IssueDate,
                DueDate = i.DueDate,
                Subtotal = i.Subtotal,
                DiscountAmount = i.DiscountAmount,
                TaxAmount = i.TaxAmount,
                TotalAmount = i.TotalAmount,
                Notes = i.Notes,
                Terms = i.Terms,
                PdfPath = i.PdfPath,
                PdfGeneratedAt = i.PdfGeneratedAt,
                DeletedAt = i.DeletedAt,
                Items = i.Items.Select(x => new InvoiceItem
                {
                    BusinessId = businessId,
                    InvoiceId = id,
                    ProductId = Remap(map.Products, x.ProductId),
                    Description = x.Description,
                    Quantity = x.Quantity,
                    UnitPrice = x.UnitPrice,
                    DiscountAmount = x.DiscountAmount,
                    TaxRateBps = x.TaxRateBps,
                    TaxAmount = x.TaxAmount,
                    LineTotal = x.LineTotal,
                }).ToList(),
            });
            counts.InvoicesInserted++;
        }
    }

    private void RestoreQuotations(BackupExportDto backup, long businessId, ExistingIds existing,
        TakenIds taken, RestoreIdMap map, RestoreCounts counts,
        Dictionary<string, Dictionary<long, long>> restored)
    {
        // The quote number is unique per business: see RestoreSales.
        var numbers = _db.Quotations
            .Where(q => q.BusinessId == businessId)
            .Select(q => q.QuoteNumber)
            .ToHashSet(StringComparer.OrdinalIgnoreCase);

        foreach (var q in backup.Quotations)
        {
            if (AlreadyRestored(restored, EntityTypes.Quotation, q.Id))
            {
                counts.QuotationsSkipped++;
                continue;
            }
            if (!existing.Quotations.Add(q.Id) || numbers.Contains(q.QuoteNumber))
            {
                counts.QuotationsSkipped++;
                continue;
            }
            numbers.Add(q.QuoteNumber);

            var id = taken.NextQuotation(q.Id);
            map.Quotations[q.Id] = id;
            _db.Quotations.Add(new Quotation
            {
                Id = id,
                BusinessId = businessId,
                QuoteNumber = q.QuoteNumber,
                CustomerId = Remap(map.Customers, q.CustomerId),
                Status = q.Status,
                IssueDate = q.IssueDate,
                ValidUntil = q.ValidUntil,
                Subtotal = q.Subtotal,
                DiscountAmount = q.DiscountAmount,
                TaxAmount = q.TaxAmount,
                TotalAmount = q.TotalAmount,
                Notes = q.Notes,
                Terms = q.Terms,
                ConvertedSaleId = Remap(map.Sales, q.ConvertedSaleId),
                PdfPath = q.PdfPath,
                PdfGeneratedAt = q.PdfGeneratedAt,
                DeletedAt = q.DeletedAt,
                Items = q.Items.Select(x => new QuotationItem
                {
                    BusinessId = businessId,
                    QuotationId = id,
                    ProductId = Remap(map.Products, x.ProductId),
                    Description = x.Description,
                    Quantity = x.Quantity,
                    UnitPrice = x.UnitPrice,
                    DiscountAmount = x.DiscountAmount,
                    TaxRateBps = x.TaxRateBps,
                    TaxAmount = x.TaxAmount,
                    LineTotal = x.LineTotal,
                }).ToList(),
            });
            counts.QuotationsInserted++;
        }
    }

    /// <summary>
    /// Whether an earlier restore of this same file already wrote this payload
    /// row. Checked first, because it is the only test that still works when
    /// the first restore had to re-home the row onto a free id or the user has
    /// since renamed it.
    /// </summary>
    private static bool AlreadyRestored(
        Dictionary<string, Dictionary<long, long>> restored, string entityType, long sourceId)
        => restored.TryGetValue(entityType, out var entries) && entries.ContainsKey(sourceId);

    /// <summary>
    /// The key that identifies a backup file. Derived only from facts inside
    /// the payload (which business it came from, when it was taken), so the
    /// same file always produces the same key and a different export does not.
    /// </summary>
    private static string BackupKeyFor(BackupExportDto backup)
        => $"{backup.BusinessId}:{backup.ExportedAt.Ticks}";

    /// <summary>
    /// Whether this payload row was written by the run in progress. Rows
    /// skipped because an earlier restore already wrote them are not recorded
    /// again, so the ledger has exactly one entry per written row.
    /// </summary>
    private static bool WasWrittenThisRun(
        string entityType, long sourceId, Dictionary<string, Dictionary<long, long>> previouslyRestored)
        => !previouslyRestored.TryGetValue(entityType, out var entries)
            || !entries.ContainsKey(sourceId);

    /// <summary>
    /// Rewrites a nullable foreign key through the restore map. A null stays
    /// null; an id with no map entry (the row was skipped because it was
    /// already present) is returned unchanged, because that row still exists
    /// under its original id.
    /// </summary>
    private static long? Remap(IReadOnlyDictionary<long, long> map, long? id)
        => id is { } value ? Remap(map, value) : null;

    /// <summary>
    /// Rewrites a non-nullable foreign key through the restore map.
    /// </summary>
    private static long Remap(IReadOnlyDictionary<long, long> map, long id)
        => map.TryGetValue(id, out var mapped) ? mapped : id;

    /// <summary>
    /// Every id currently in one table, ignoring the tenant filter. Used to
    /// detect values that are already taken, so the restore can re-home a
    /// colliding row instead of failing on the primary key.
    /// </summary>
    private static async Task<HashSet<long>> AllIdsAsync<T>(
        IQueryable<T> set, CancellationToken cancellationToken)
        where T : class
        => [.. await set
            .IgnoreQueryFilters()
            .Select(e => EF.Property<long>(e, "Id"))
            .ToListAsync(cancellationToken)];

    /// <summary>
    /// Every id currently owned by <paramref name="businessId"/> in one table.
    /// The tenant filter is bypassed so soft-deleted rows count too (restoring
    /// over a soft-deleted row would collide on the primary key), but the query
    /// is explicitly scoped to the target business — a global scan would see
    /// other businesses' ids on a shared database and skip a legitimate insert.
    /// </summary>
    private static async Task<HashSet<long>> BusinessIdsAsync<T>(
        IQueryable<T> set, long businessId, CancellationToken cancellationToken)
        where T : class
        => [.. await set
            .IgnoreQueryFilters()
            .Where(e => EF.Property<long>(e, "BusinessId") == businessId)
            .Select(e => EF.Property<long>(e, "Id"))
            .ToListAsync(cancellationToken)];

    /// <summary>
    /// Allocates a usable id for a row whose payload id is already taken by
    /// someone else. Ids come from a shared sequence in the database, so this
    /// walks upward from the payload id until it finds a free slot and records
    /// it as used, guaranteeing the batch itself never collides.
    /// </summary>
    private sealed class TakenIds
    {
        public HashSet<long> Units { get; init; } = [];
        public HashSet<long> Categories { get; init; } = [];
        public HashSet<long> Products { get; init; } = [];
        public HashSet<long> Customers { get; init; } = [];
        public HashSet<long> Suppliers { get; init; } = [];
        public HashSet<long> Methods { get; init; } = [];
        public HashSet<long> Sales { get; init; } = [];
        public HashSet<long> Purchases { get; init; } = [];
        public HashSet<long> Expenses { get; init; } = [];
        public HashSet<long> Incomes { get; init; } = [];
        public HashSet<long> Payments { get; init; } = [];
        public HashSet<long> Invoices { get; init; } = [];
        public HashSet<long> Quotations { get; init; } = [];

        public long NextUnit(long id) => Next(Units, id);
        public long NextCategory(long id) => Next(Categories, id);
        public long NextProduct(long id) => Next(Products, id);
        public long NextCustomer(long id) => Next(Customers, id);
        public long NextSupplier(long id) => Next(Suppliers, id);
        public long NextMethod(long id) => Next(Methods, id);
        public long NextSale(long id) => Next(Sales, id);
        public long NextPurchase(long id) => Next(Purchases, id);
        public long NextExpense(long id) => Next(Expenses, id);
        public long NextIncome(long id) => Next(Incomes, id);
        public long NextPayment(long id) => Next(Payments, id);
        public long NextInvoice(long id) => Next(Invoices, id);
        public long NextQuotation(long id) => Next(Quotations, id);

        private static long Next(HashSet<long> taken, long id)
        {
            var candidate = id;
            while (!taken.Add(candidate)) candidate++;
            return candidate;
        }
    }

    /// <summary>
    /// Payload id to written id, per table, for the current restore. References
    /// are rewritten through it. Tables whose rows were all inserted verbatim
    /// still get entries mapping each id to itself, so <see cref="Remap"/> can
    /// be applied unconditionally.
    /// </summary>
    private sealed class RestoreIdMap
    {
        public Dictionary<long, long> Units { get; } = [];
        public Dictionary<long, long> Categories { get; } = [];
        public Dictionary<long, long> Products { get; } = [];
        public Dictionary<long, long> Customers { get; } = [];
        public Dictionary<long, long> Suppliers { get; } = [];
        public Dictionary<long, long> Methods { get; } = [];
        public Dictionary<long, long> Sales { get; } = [];
        public Dictionary<long, long> Purchases { get; } = [];
        public Dictionary<long, long> Expenses { get; } = [];
        public Dictionary<long, long> Incomes { get; } = [];
        public Dictionary<long, long> Invoices { get; } = [];
        public Dictionary<long, long> Quotations { get; } = [];

        /// <summary>
        /// The party dictionary a payment's <c>PartyType</c> points at.
        /// </summary>
        public IReadOnlyDictionary<long, long> Parties(Khata.Domain.Enums.PartyType partyType)
            => partyType == Khata.Domain.Enums.PartyType.Supplier ? Suppliers : Customers;

        /// <summary>
        /// Every table's map, labelled by the entity type stored in the ledger,
        /// so the restore can persist exactly the pairs it wrote.
        /// </summary>
        public IEnumerable<KeyValuePair<string, Dictionary<long, long>>> Pairs =>
        [
            new(EntityTypes.Unit, Units),
            new(EntityTypes.Category, Categories),
            new(EntityTypes.Product, Products),
            new(EntityTypes.Customer, Customers),
            new(EntityTypes.Supplier, Suppliers),
            new(EntityTypes.PaymentMethod, Methods),
            new(EntityTypes.Sale, Sales),
            new(EntityTypes.Purchase, Purchases),
            new(EntityTypes.Expense, Expenses),
            new(EntityTypes.Income, Incomes),
            new(EntityTypes.Invoice, Invoices),
            new(EntityTypes.Quotation, Quotations),
        ];

        /// <summary>
        /// Reloads the maps from a previous restore's ledger, so a repeated
        /// restore resolves foreign keys against the ids that were actually
        /// written rather than the ones the payload asked for.
        /// </summary>
        public static RestoreIdMap FromLedger(
            Dictionary<string, Dictionary<long, long>> restored)
        {
            var map = new RestoreIdMap();

            foreach (var (entityType, target) in map.Pairs)
            {
                if (!restored.TryGetValue(entityType, out var entries)) continue;

                foreach (var (sourceId, targetId) in entries) target[sourceId] = targetId;
            }

            return map;
        }
    }

    /// <summary>
    /// The ledger's <c>EntityType</c> labels. Kept in one place so the write and
    /// the lookup can never disagree.
    /// </summary>
    private static class EntityTypes
    {
        public const string Unit = "unit";
        public const string Category = "product_category";
        public const string Product = "product";
        public const string Customer = "customer";
        public const string Supplier = "supplier";
        public const string PaymentMethod = "payment_method";
        public const string Sale = "sale";
        public const string Purchase = "purchase";
        public const string Expense = "expense";
        public const string Income = "income";
        public const string Payment = "payment";
        public const string Invoice = "invoice";
        public const string Quotation = "quotation";
    }

    private sealed class ExistingIds
    {
        public HashSet<long> Units { get; init; } = [];
        public HashSet<long> Categories { get; init; } = [];
        public HashSet<long> Products { get; init; } = [];
        public HashSet<long> Customers { get; init; } = [];
        public HashSet<long> Suppliers { get; init; } = [];
        public HashSet<long> Methods { get; init; } = [];
        public HashSet<long> Sales { get; init; } = [];
        public HashSet<long> Purchases { get; init; } = [];
        public HashSet<long> Expenses { get; init; } = [];
        public HashSet<long> Incomes { get; init; } = [];
        public HashSet<long> Payments { get; init; } = [];
        public HashSet<long> Invoices { get; init; } = [];
        public HashSet<long> Quotations { get; init; } = [];
    }

    private sealed class RestoreCounts
    {
        public int ProductsInserted { get; set; }
        public int ProductsSkipped { get; set; }
        public int CustomersInserted { get; set; }
        public int CustomersSkipped { get; set; }
        public int SuppliersInserted { get; set; }
        public int SuppliersSkipped { get; set; }
        public int SalesInserted { get; set; }
        public int SalesSkipped { get; set; }
        public int PurchasesInserted { get; set; }
        public int PurchasesSkipped { get; set; }
        public int ExpensesInserted { get; set; }
        public int ExpensesSkipped { get; set; }
        public int IncomesInserted { get; set; }
        public int IncomesSkipped { get; set; }
        public int PaymentsInserted { get; set; }
        public int PaymentsSkipped { get; set; }
        public int InvoicesInserted { get; set; }
        public int InvoicesSkipped { get; set; }
        public int QuotationsInserted { get; set; }
        public int QuotationsSkipped { get; set; }
        public int PaymentMethodsInserted { get; set; }
        public int PaymentMethodsMatched { get; set; }
        public int UnitsInserted { get; set; }
        public int UnitsMatched { get; set; }
    }
}
