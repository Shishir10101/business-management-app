namespace Khata.Infrastructure.Services;

using System.Globalization;
using System.Text;
using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Application.Interfaces;
using Khata.Domain.Exceptions;
using Khata.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

/// <summary>
/// Dashboard and reports. Money aggregates run in SQL; anything involving
/// <c>decimal</c> quantities is aggregated in memory (SQLite stores decimals as
/// text, so summing them server-side is not reliable).
/// </summary>
public class ReportService : IReportService
{
    private const int MaxRangeDays = 366;
    private const int DashboardTrendDays = 14;

    private readonly KhataDbContext _db;
    private readonly ICurrentUserService _currentUser;
    private readonly IDateTimeProvider _clock;

    public ReportService(KhataDbContext db, ICurrentUserService currentUser, IDateTimeProvider clock)
    {
        _db = db;
        _currentUser = currentUser;
        _clock = clock;
    }

    private long BusinessId =>
        _currentUser.BusinessId ?? throw new UnauthorizedException();

    // ==============================================================
    // Dashboard
    // ==============================================================

    public async Task<DashboardDto> GetDashboardAsync(CancellationToken cancellationToken = default)
    {
        var today = _clock.Today;
        var monthStart = new DateOnly(today.Year, today.Month, 1);
        var trendStart = today.AddDays(-(DashboardTrendDays - 1));

        var todaySales = await SalesSummaryAsync(today, today, cancellationToken);
        var monthSales = await SalesSummaryAsync(monthStart, today, cancellationToken);

        var todayCogs = await CostOfGoodsAsync(today, today, cancellationToken);
        var monthCogs = await CostOfGoodsAsync(monthStart, today, cancellationToken);

        var todayPurchases = await PurchasesTotalAsync(today, today, cancellationToken);
        var monthPurchases = await PurchasesTotalAsync(monthStart, today, cancellationToken);
        var todayExpenses = await ExpensesTotalAsync(today, today, cancellationToken);
        var monthExpenses = await ExpensesTotalAsync(monthStart, today, cancellationToken);
        var todayIncome = await IncomeTotalAsync(today, today, cancellationToken);
        var monthIncome = await IncomeTotalAsync(monthStart, today, cancellationToken);

        var balances = await GetReceivablePayableAsync(cancellationToken);
        var stock = await GetStockReportAsync(false, null, cancellationToken);

        var todayRevenue = NetRevenue(todaySales);
        var monthRevenue = NetRevenue(monthSales);
        var todayGross = todayRevenue - todayCogs;
        var monthGross = monthRevenue - monthCogs;

        return new DashboardDto(
            AsOf: today,
            TodaySales: todaySales,
            MonthSales: monthSales,
            TodayPurchases: todayPurchases,
            TodayExpenses: todayExpenses,
            TodayIncome: todayIncome,
            TodayGrossProfit: todayGross,
            TodayNetProfit: todayGross + todayIncome - todayExpenses,
            MonthPurchases: monthPurchases,
            MonthExpenses: monthExpenses,
            MonthIncome: monthIncome,
            MonthGrossProfit: monthGross,
            MonthNetProfit: monthGross + monthIncome - monthExpenses,
            TotalReceivable: balances.TotalReceivable,
            TotalPayable: balances.TotalPayable,
            CustomerAdvances: balances.CustomerAdvances,
            SupplierAdvances: balances.SupplierAdvances,
            StockCostValue: stock.TotalCostValue,
            StockRetailValue: stock.TotalRetailValue,
            LowStockCount: stock.LowStockCount,
            ProductCount: stock.ProductCount,
            CustomerCount: await _db.Customers
                .CountAsync(c => c.DeletedAt == null && c.BusinessId == BusinessId, cancellationToken),
            Trend: await BuildTrendAsync(trendStart, today, "day", cancellationToken),
            TopProducts: await TopProductsAsync(monthStart, today, 5, cancellationToken),
            TopCustomers: await TopCustomersAsync(monthStart, today, 5, cancellationToken));
    }

    // ==============================================================
    // Reports
    // ==============================================================

    public async Task<SalesReportDto> GetSalesReportAsync(
        DateOnly dateFrom, DateOnly dateTo, string groupBy, int top,
        CancellationToken cancellationToken = default)
    {
        var (from, to, grouping) = Normalize(dateFrom, dateTo, groupBy);
        var take = Math.Clamp(top, 1, 50);

        return new SalesReportDto(
            from, to, grouping,
            await SalesSummaryAsync(from, to, cancellationToken),
            await BuildTrendAsync(from, to, grouping, cancellationToken),
            await TopProductsAsync(from, to, take, cancellationToken),
            await TopCustomersAsync(from, to, take, cancellationToken));
    }

    public async Task<PurchaseReportDto> GetPurchaseReportAsync(
        DateOnly dateFrom, DateOnly dateTo, string groupBy, int top,
        CancellationToken cancellationToken = default)
    {
        var (from, to, grouping) = Normalize(dateFrom, dateTo, groupBy);
        var take = Math.Clamp(top, 1, 50);

        var totals = await _db.Purchases
            .Where(p => p.DeletedAt == null && p.BusinessId == BusinessId
                && p.PurchaseDate >= from && p.PurchaseDate <= to)
            .GroupBy(p => p.BusinessId)
            .Select(g => new AmountSummaryDto(
                g.Count(),
                g.Sum(x => x.Subtotal),
                g.Sum(x => x.DiscountAmount),
                g.Sum(x => x.TaxAmount),
                g.Sum(x => x.TotalAmount),
                g.Sum(x => x.PaidAmount),
                g.Sum(x => x.DueAmount)))
            .FirstOrDefaultAsync(cancellationToken) ?? Empty;

        var suppliers = await _db.Purchases
            .Where(p => p.DeletedAt == null && p.BusinessId == BusinessId
                && p.PurchaseDate >= from && p.PurchaseDate <= to && p.SupplierId != null)
            .Select(p => new { SupplierId = p.SupplierId!.Value, Name = p.Supplier!.Name, p.TotalAmount })
            .ToListAsync(cancellationToken);

        var topSuppliers = suppliers
            .GroupBy(s => new { s.SupplierId, s.Name })
            .Select(g => new TopItemDto(g.Key.SupplierId, g.Key.Name, g.Sum(x => x.TotalAmount), 0, g.Count()))
            .OrderByDescending(x => x.Amount)
            .Take(take)
            .ToList();

        return new PurchaseReportDto(
            from, to, grouping, totals,
            await BuildTrendAsync(from, to, grouping, cancellationToken),
            topSuppliers);
    }

    public async Task<ExpenseReportDto> GetExpenseReportAsync(
        DateOnly dateFrom, DateOnly dateTo, string groupBy,
        CancellationToken cancellationToken = default)
    {
        var (from, to, grouping) = Normalize(dateFrom, dateTo, groupBy);

        var rows = await _db.Expenses
            .Where(e => e.DeletedAt == null && e.BusinessId == BusinessId
                && e.ExpenseDate >= from && e.ExpenseDate <= to)
            .Select(e => new { e.Category, e.Amount })
            .ToListAsync(cancellationToken);

        var byCategory = rows
            .GroupBy(r => r.Category)
            .Select(g => new CategoryAmountDto(g.Key, g.Sum(x => x.Amount), g.Count()))
            .OrderByDescending(c => c.Amount)
            .ToList();

        return new ExpenseReportDto(
            from, to, grouping,
            rows.Sum(r => r.Amount), rows.Count, byCategory,
            await BuildTrendAsync(from, to, grouping, cancellationToken));
    }

    public async Task<IncomeReportDto> GetIncomeReportAsync(
        DateOnly dateFrom, DateOnly dateTo, string groupBy,
        CancellationToken cancellationToken = default)
    {
        var (from, to, grouping) = Normalize(dateFrom, dateTo, groupBy);

        var rows = await _db.Incomes
            .Where(i => i.DeletedAt == null && i.BusinessId == BusinessId
                && i.IncomeDate >= from && i.IncomeDate <= to)
            .Select(i => new { i.Source, i.Amount })
            .ToListAsync(cancellationToken);

        var bySource = rows
            .GroupBy(r => r.Source)
            .Select(g => new CategoryAmountDto(g.Key, g.Sum(x => x.Amount), g.Count()))
            .OrderByDescending(c => c.Amount)
            .ToList();

        return new IncomeReportDto(
            from, to, grouping,
            rows.Sum(r => r.Amount), rows.Count, bySource,
            await BuildTrendAsync(from, to, grouping, cancellationToken));
    }

    public async Task<ProfitLossDto> GetProfitLossAsync(
        DateOnly dateFrom, DateOnly dateTo, CancellationToken cancellationToken = default)
    {
        var (from, to, _) = Normalize(dateFrom, dateTo, "day");

        var sales = await SalesSummaryAsync(from, to, cancellationToken);
        var revenue = NetRevenue(sales);
        var cogs = await CostOfGoodsAsync(from, to, cancellationToken);
        var gross = revenue - cogs;

        var income = await IncomeTotalAsync(from, to, cancellationToken);
        var expenses = await ExpensesTotalAsync(from, to, cancellationToken);

        var expenseRows = await _db.Expenses
            .Where(e => e.DeletedAt == null && e.BusinessId == BusinessId
                && e.ExpenseDate >= from && e.ExpenseDate <= to)
            .Select(e => new { e.Category, e.Amount })
            .ToListAsync(cancellationToken);

        var byCategory = expenseRows
            .GroupBy(r => r.Category)
            .Select(g => new CategoryAmountDto(g.Key, g.Sum(x => x.Amount), g.Count()))
            .OrderByDescending(c => c.Amount)
            .ToList();

        return new ProfitLossDto(
            from, to, revenue, cogs, gross, income, expenses,
            gross + income - expenses, sales.Tax, byCategory);
    }

    public async Task<StockReportDto> GetStockReportAsync(
        bool lowStockOnly, string? search, CancellationToken cancellationToken = default)
    {
        var rows = await _db.ProductStocks
            .Where(s => s.BusinessId == BusinessId && s.Product.DeletedAt == null)
            .Select(s => new
            {
                s.ProductId,
                s.Product.Name,
                CategoryName = s.Product.Category == null ? null : s.Product.Category.Name,
                UnitShortName = s.Product.Unit == null ? null : s.Product.Unit.ShortName,
                s.Quantity,
                s.MinQuantity,
                Cost = s.Product.CostPrice,
                Selling = s.Product.SellingPrice,
            })
            .ToListAsync(cancellationToken);

        // Products without a stock row are treated as zero stock.
        var withStock = rows.Select(r => new StockReportRowDto(
            r.ProductId, r.Name, r.CategoryName, r.UnitShortName, r.Quantity,
            r.Cost, r.Selling,
            (long)Math.Round(r.Cost * r.Quantity, MidpointRounding.AwayFromZero),
            (long)Math.Round(r.Selling * r.Quantity, MidpointRounding.AwayFromZero),
            r.MinQuantity > 0 && r.Quantity <= r.MinQuantity)).ToList();

        var filtered = withStock.AsEnumerable();
        if (lowStockOnly)
            filtered = filtered.Where(i => i.IsLowStock);
        if (!string.IsNullOrWhiteSpace(search))
        {
            var query = search.Trim().ToLowerInvariant();
            filtered = filtered.Where(i => i.Name.ToLowerInvariant().Contains(query));
        }

        var items = filtered.OrderBy(i => i.Name).ToList();

        return new StockReportDto(
            TotalCostValue: items.Sum(i => i.CostValue),
            TotalRetailValue: items.Sum(i => i.RetailValue),
            PotentialMargin: items.Sum(i => i.RetailValue - i.CostValue),
            ProductCount: items.Count,
            LowStockCount: withStock.Count(i => i.IsLowStock),
            Items: items);
    }

    public async Task<VatRegisterDto> GetVatSalesRegisterAsync(
        DateOnly dateFrom, DateOnly dateTo,
        CancellationToken cancellationToken = default)
    {
        var (from, to, _) = Normalize(dateFrom, dateTo, "day");

        var rows = await _db.Sales
            .Where(s => s.DeletedAt == null && s.BusinessId == BusinessId
                && s.SaleDate >= from && s.SaleDate <= to)
            .OrderBy(s => s.SaleDate).ThenBy(s => s.Id)
            .Select(s => new VatRegisterRowDto(
                s.SaleDate,
                s.InvoiceNumber,
                s.Customer == null ? "Walk-in" : s.Customer.Name,
                s.Customer == null ? null : s.Customer.PanNumber,
                s.Subtotal - s.DiscountAmount,
                s.TaxAmount,
                s.TotalAmount))
            .ToListAsync(cancellationToken);

        return new VatRegisterDto(
            from, to, rows.Count,
            rows.Sum(r => r.TaxableAmount),
            rows.Sum(r => r.TaxAmount),
            rows.Sum(r => r.TotalAmount),
            rows);
    }

    public async Task<VatRegisterDto> GetVatPurchaseRegisterAsync(
        DateOnly dateFrom, DateOnly dateTo,
        CancellationToken cancellationToken = default)
    {
        var (from, to, _) = Normalize(dateFrom, dateTo, "day");

        var rows = await _db.Purchases
            .Where(p => p.DeletedAt == null && p.BusinessId == BusinessId
                && p.PurchaseDate >= from && p.PurchaseDate <= to)
            .OrderBy(p => p.PurchaseDate).ThenBy(p => p.Id)
            .Select(p => new VatRegisterRowDto(
                p.PurchaseDate,
                p.BillNumber,
                p.Supplier == null ? "—" : p.Supplier.Name,
                p.Supplier == null ? null : p.Supplier.PanNumber,
                p.Subtotal - p.DiscountAmount,
                p.TaxAmount,
                p.TotalAmount))
            .ToListAsync(cancellationToken);

        return new VatRegisterDto(
            from, to, rows.Count,
            rows.Sum(r => r.TaxableAmount),
            rows.Sum(r => r.TaxAmount),
            rows.Sum(r => r.TotalAmount),
            rows);
    }

    public async Task<ReceivablesAgingDto> GetReceivablesAgingAsync(
        DateOnly? asOf, CancellationToken cancellationToken = default)
    {
        var today = asOf ?? _clock.Today;
        var sales = await _db.Sales
            .Where(s => s.DeletedAt == null && s.BusinessId == BusinessId
                && s.DueAmount > 0 && s.CustomerId != null)
            .Select(s => new
            {
                s.CustomerId,
                s.Customer!.Name,
                s.Customer.PhoneNumber,
                s.SaleDate,
                s.DueAmount,
            })
            .ToListAsync(cancellationToken);

        var customers = sales
            .GroupBy(s => new { s.CustomerId, s.Name, s.PhoneNumber })
            .Select(g =>
            {
                var buckets = g.ToLookup(x =>
                {
                    var age = today.DayNumber - x.SaleDate.DayNumber;
                    return age switch
                    {
                        <= 30 => 0,
                        <= 60 => 1,
                        <= 90 => 2,
                        <= 120 => 3,
                        _ => 4,
                    };
                });
                return new AgingRowDto(
                    g.Key.CustomerId!.Value,
                    g.Key.Name,
                    g.Key.PhoneNumber,
                    buckets[0].Sum(x => x.DueAmount),
                    buckets[1].Sum(x => x.DueAmount),
                    buckets[2].Sum(x => x.DueAmount),
                    buckets[3].Sum(x => x.DueAmount),
                    buckets[4].Sum(x => x.DueAmount),
                    g.Sum(x => x.DueAmount));
            })
            .OrderByDescending(r => r.Total)
            .ToList();

        return new ReceivablesAgingDto(
            today,
            customers.Count,
            customers.Sum(r => r.Current),
            customers.Sum(r => r.Days1To30),
            customers.Sum(r => r.Days31To60),
            customers.Sum(r => r.Days61To90),
            customers.Sum(r => r.Over90),
            customers.Sum(r => r.Total),
            customers);
    }

    public async Task<ReceivablePayableReportDto> GetReceivablePayableAsync(
        CancellationToken cancellationToken = default)
    {
        var accounts = await _db.LedgerAccounts
            .Where(a => a.BusinessId == BusinessId)
            .Select(a => new { a.PartyType, a.PartyId, a.CurrentBalance })
            .ToListAsync(cancellationToken);

        var customerIds = accounts
            .Where(a => a.PartyType == Domain.Enums.PartyType.Customer)
            .Select(a => a.PartyId).Distinct().ToList();
        var supplierIds = accounts
            .Where(a => a.PartyType == Domain.Enums.PartyType.Supplier)
            .Select(a => a.PartyId).Distinct().ToList();

        var customers = await _db.Customers
            .Where(c => customerIds.Contains(c.Id))
            .Select(c => new { c.Id, c.Name, c.PhoneNumber })
            .ToListAsync(cancellationToken);
        var suppliers = await _db.Suppliers
            .Where(s => supplierIds.Contains(s.Id))
            .Select(s => new { s.Id, s.Name, s.PhoneNumber })
            .ToListAsync(cancellationToken);

        var customerNames = customers.ToDictionary(c => c.Id, c => (c.Name, c.PhoneNumber));
        var supplierNames = suppliers.ToDictionary(s => s.Id, s => (s.Name, s.PhoneNumber));

        // Open documents per party, so the report can show how many are unpaid.
        var openSales = await _db.Sales
            .Where(s => s.DeletedAt == null && s.BusinessId == BusinessId && s.DueAmount > 0 && s.CustomerId != null)
            .Select(s => s.CustomerId!.Value)
            .ToListAsync(cancellationToken);
        var openPurchases = await _db.Purchases
            .Where(p => p.DeletedAt == null && p.BusinessId == BusinessId && p.DueAmount > 0 && p.SupplierId != null)
            .Select(p => p.SupplierId!.Value)
            .ToListAsync(cancellationToken);

        var openSalesCount = openSales.GroupBy(id => id).ToDictionary(g => g.Key, g => g.Count());
        var openPurchaseCount = openPurchases.GroupBy(id => id).ToDictionary(g => g.Key, g => g.Count());

        var customerAccounts = accounts.Where(a => a.PartyType == Domain.Enums.PartyType.Customer).ToList();
        var supplierAccounts = accounts.Where(a => a.PartyType == Domain.Enums.PartyType.Supplier).ToList();

        var receivables = customerAccounts
            .Where(a => a.CurrentBalance > 0)
            .Select(a => new OutstandingPartyDto(
                a.PartyId,
                customerNames.GetValueOrDefault(a.PartyId).Name ?? $"Customer #{a.PartyId}",
                customerNames.GetValueOrDefault(a.PartyId).PhoneNumber,
                a.CurrentBalance,
                openSalesCount.GetValueOrDefault(a.PartyId)))
            .OrderByDescending(p => p.Balance)
            .ToList();

        var payables = supplierAccounts
            .Where(a => a.CurrentBalance > 0)
            .Select(a => new OutstandingPartyDto(
                a.PartyId,
                supplierNames.GetValueOrDefault(a.PartyId).Name ?? $"Supplier #{a.PartyId}",
                supplierNames.GetValueOrDefault(a.PartyId).PhoneNumber,
                a.CurrentBalance,
                openPurchaseCount.GetValueOrDefault(a.PartyId)))
            .OrderByDescending(p => p.Balance)
            .ToList();

        return new ReceivablePayableReportDto(
            TotalReceivable: receivables.Sum(p => p.Balance),
            TotalPayable: payables.Sum(p => p.Balance),
            CustomerAdvances: -customerAccounts.Where(a => a.CurrentBalance < 0).Sum(a => a.CurrentBalance),
            SupplierAdvances: -supplierAccounts.Where(a => a.CurrentBalance < 0).Sum(a => a.CurrentBalance),
            Receivables: receivables,
            Payables: payables);
    }

    // ==============================================================
    // CSV export
    // ==============================================================

    public async Task<CsvExportDto> ExportCsvAsync(
        string reportType, DateOnly dateFrom, DateOnly dateTo,
        CancellationToken cancellationToken = default)
    {
        var type = (reportType ?? string.Empty).Trim().ToLowerInvariant();
        var (from, to, _) = Normalize(dateFrom, dateTo, "day");
        var stamp = $"{from:yyyyMMdd}-{to:yyyyMMdd}";

        switch (type)
        {
            case "sales":
            {
                var rows = await _db.Sales
                    .Where(s => s.DeletedAt == null && s.BusinessId == BusinessId
                        && s.SaleDate >= from && s.SaleDate <= to)
                    .OrderBy(s => s.SaleDate).ThenBy(s => s.Id)
                    .Select(s => new
                    {
                        s.InvoiceNumber, s.SaleDate,
                        Customer = s.Customer == null ? "Walk-in" : s.Customer.Name,
                        s.SaleType, s.PaymentStatus,
                        s.Subtotal, s.DiscountAmount, s.TaxAmount, s.TotalAmount,
                        s.PaidAmount, s.DueAmount,
                    })
                    .ToListAsync(cancellationToken);

                var csv = Csv(
                    ["Invoice", "Date", "Customer", "Type", "Status", "Subtotal", "Discount", "Tax", "Total", "Paid", "Due"],
                    rows.Select(r => new[]
                    {
                        r.InvoiceNumber, r.SaleDate.ToString("yyyy-MM-dd"), r.Customer,
                        r.SaleType.ToString(), r.PaymentStatus.ToString(),
                        Money(r.Subtotal), Money(r.DiscountAmount), Money(r.TaxAmount),
                        Money(r.TotalAmount), Money(r.PaidAmount), Money(r.DueAmount),
                    }));

                return new CsvExportDto($"sales-{stamp}.csv", csv);
            }

            case "purchases":
            {
                var rows = await _db.Purchases
                    .Where(p => p.DeletedAt == null && p.BusinessId == BusinessId
                        && p.PurchaseDate >= from && p.PurchaseDate <= to)
                    .OrderBy(p => p.PurchaseDate).ThenBy(p => p.Id)
                    .Select(p => new
                    {
                        p.BillNumber, p.PurchaseDate,
                        Supplier = p.Supplier == null ? "—" : p.Supplier.Name,
                        p.PurchaseType, p.PaymentStatus,
                        p.Subtotal, p.DiscountAmount, p.TaxAmount, p.TotalAmount,
                        p.PaidAmount, p.DueAmount,
                    })
                    .ToListAsync(cancellationToken);

                var csv = Csv(
                    ["Bill", "Date", "Supplier", "Type", "Status", "Subtotal", "Discount", "Tax", "Total", "Paid", "Due"],
                    rows.Select(r => new[]
                    {
                        r.BillNumber, r.PurchaseDate.ToString("yyyy-MM-dd"), r.Supplier,
                        r.PurchaseType.ToString(), r.PaymentStatus.ToString(),
                        Money(r.Subtotal), Money(r.DiscountAmount), Money(r.TaxAmount),
                        Money(r.TotalAmount), Money(r.PaidAmount), Money(r.DueAmount),
                    }));

                return new CsvExportDto($"purchases-{stamp}.csv", csv);
            }

            case "expenses":
            {
                var rows = await _db.Expenses
                    .Where(e => e.DeletedAt == null && e.BusinessId == BusinessId
                        && e.ExpenseDate >= from && e.ExpenseDate <= to)
                    .OrderBy(e => e.ExpenseDate).ThenBy(e => e.Id)
                    .Select(e => new { e.ExpenseDate, e.Category, e.Description, e.Amount, e.PaymentMethod, e.Reference })
                    .ToListAsync(cancellationToken);

                var csv = Csv(
                    ["Date", "Category", "Description", "Amount", "Method", "Reference"],
                    rows.Select(r => new[]
                    {
                        r.ExpenseDate.ToString("yyyy-MM-dd"), r.Category, r.Description ?? string.Empty,
                        Money(r.Amount), r.PaymentMethod ?? string.Empty, r.Reference ?? string.Empty,
                    }));

                return new CsvExportDto($"expenses-{stamp}.csv", csv);
            }

            case "income":
            {
                var rows = await _db.Incomes
                    .Where(i => i.DeletedAt == null && i.BusinessId == BusinessId
                        && i.IncomeDate >= from && i.IncomeDate <= to)
                    .OrderBy(i => i.IncomeDate).ThenBy(i => i.Id)
                    .Select(i => new { i.IncomeDate, i.Source, i.Description, i.Amount, i.PaymentMethod, i.Reference })
                    .ToListAsync(cancellationToken);

                var csv = Csv(
                    ["Date", "Source", "Description", "Amount", "Method", "Reference"],
                    rows.Select(r => new[]
                    {
                        r.IncomeDate.ToString("yyyy-MM-dd"), r.Source, r.Description ?? string.Empty,
                        Money(r.Amount), r.PaymentMethod ?? string.Empty, r.Reference ?? string.Empty,
                    }));

                return new CsvExportDto($"income-{stamp}.csv", csv);
            }

            case "profit-loss":
            {
                var pl = await GetProfitLossAsync(from, to, cancellationToken);
                var csv = Csv(
                    ["Line", "Amount"],
                    [
                        ["Period", $"{from:yyyy-MM-dd} to {to:yyyy-MM-dd}"],
                        ["Revenue (net of discount, excl. tax)", Money(pl.Revenue)],
                        ["Cost of goods sold", Money(pl.CostOfGoods)],
                        ["Gross profit", Money(pl.GrossProfit)],
                        ["Other income", Money(pl.OtherIncome)],
                        ["Expenses", Money(pl.Expenses)],
                        ["Net profit", Money(pl.NetProfit)],
                        ["Sales tax collected", Money(pl.SalesTaxCollected)],
                    ]);

                return new CsvExportDto($"profit-loss-{stamp}.csv", csv);
            }

            case "stock":
            {
                var stock = await GetStockReportAsync(false, null, cancellationToken);
                var csv = Csv(
                    ["Product", "Category", "Unit", "Quantity", "Cost price", "Selling price", "Cost value", "Retail value", "Low stock"],
                    stock.Items.Select(i => new[]
                    {
                        i.Name, i.CategoryName ?? string.Empty, i.UnitShortName ?? string.Empty,
                        i.Quantity.ToString("0.###", CultureInfo.InvariantCulture),
                        Money(i.CostPrice), Money(i.SellingPrice),
                        Money(i.CostValue), Money(i.RetailValue),
                        i.IsLowStock ? "yes" : "no",
                    }));

                return new CsvExportDto($"stock-{stamp}.csv", csv);
            }

            default:
                throw new BusinessRuleException("unknown_report",
                    "reportType must be one of: sales, purchases, expenses, income, profit-loss, stock.");
        }
    }

    // ==============================================================
    // Helpers
    // ==============================================================

    private static readonly AmountSummaryDto Empty = new(0, 0, 0, 0, 0, 0, 0);

    /// <summary>Net revenue: subtotal less discounts, excluding collected tax.</summary>
    private static long NetRevenue(AmountSummaryDto summary) => summary.Subtotal - summary.Discount;

    private (DateOnly From, DateOnly To, string GroupBy) Normalize(
        DateOnly dateFrom, DateOnly dateTo, string groupBy)
    {
        if (dateTo < dateFrom)
            throw new BusinessRuleException("invalid_range", "dateTo must be on or after dateFrom.");

        if (dateTo.DayNumber - dateFrom.DayNumber > MaxRangeDays)
            throw new BusinessRuleException("range_too_large",
                $"The date range cannot exceed {MaxRangeDays} days.");

        var grouping = (groupBy ?? "day").Trim().ToLowerInvariant() switch
        {
            "day" or "daily" => "day",
            "week" or "weekly" => "week",
            "month" or "monthly" => "month",
            _ => throw new BusinessRuleException("invalid_group_by",
                "groupBy must be one of: day, week, month."),
        };

        return (dateFrom, dateTo, grouping);
    }

    private async Task<AmountSummaryDto> SalesSummaryAsync(
        DateOnly from, DateOnly to, CancellationToken cancellationToken)
        => await _db.Sales
            .Where(s => s.DeletedAt == null && s.BusinessId == BusinessId
                && s.SaleDate >= from && s.SaleDate <= to)
            .GroupBy(s => s.BusinessId)
            .Select(g => new AmountSummaryDto(
                g.Count(),
                g.Sum(x => x.Subtotal),
                g.Sum(x => x.DiscountAmount),
                g.Sum(x => x.TaxAmount),
                g.Sum(x => x.TotalAmount),
                g.Sum(x => x.PaidAmount),
                g.Sum(x => x.DueAmount)))
            .FirstOrDefaultAsync(cancellationToken) ?? Empty;

    private async Task<long> PurchasesTotalAsync(DateOnly from, DateOnly to, CancellationToken cancellationToken)
        => await _db.Purchases
            .Where(p => p.DeletedAt == null && p.BusinessId == BusinessId
                && p.PurchaseDate >= from && p.PurchaseDate <= to)
            .SumAsync(p => (long?)p.TotalAmount, cancellationToken) ?? 0;

    private async Task<long> ExpensesTotalAsync(DateOnly from, DateOnly to, CancellationToken cancellationToken)
        => await _db.Expenses
            .Where(e => e.DeletedAt == null && e.BusinessId == BusinessId
                && e.ExpenseDate >= from && e.ExpenseDate <= to)
            .SumAsync(e => (long?)e.Amount, cancellationToken) ?? 0;

    private async Task<long> IncomeTotalAsync(DateOnly from, DateOnly to, CancellationToken cancellationToken)
        => await _db.Incomes
            .Where(i => i.DeletedAt == null && i.BusinessId == BusinessId
                && i.IncomeDate >= from && i.IncomeDate <= to)
            .SumAsync(i => (long?)i.Amount, cancellationToken) ?? 0;

    /// <summary>
    /// Cost of goods sold, valued at each product's **current** cost price
    /// (the app does not snapshot cost at sale time).
    /// </summary>
    private async Task<long> CostOfGoodsAsync(DateOnly from, DateOnly to, CancellationToken cancellationToken)
    {
        var lines = await _db.SaleItems
            .Where(i => i.BusinessId == BusinessId
                && i.Sale.DeletedAt == null
                && i.Sale.SaleDate >= from && i.Sale.SaleDate <= to)
            .Select(i => new { i.Quantity, Cost = i.Product.CostPrice })
            .ToListAsync(cancellationToken);

        return lines.Sum(l => (long)Math.Round(l.Cost * l.Quantity, MidpointRounding.AwayFromZero));
    }

    private async Task<List<TopItemDto>> TopProductsAsync(
        DateOnly from, DateOnly to, int take, CancellationToken cancellationToken)
    {
        var rows = await _db.SaleItems
            .Where(i => i.BusinessId == BusinessId
                && i.Sale.DeletedAt == null
                && i.Sale.SaleDate >= from && i.Sale.SaleDate <= to)
            .Select(i => new { i.ProductId, i.ProductName, i.Quantity, i.LineTotal })
            .ToListAsync(cancellationToken);

        return rows
            .GroupBy(r => new { r.ProductId, r.ProductName })
            .Select(g => new TopItemDto(
                g.Key.ProductId, g.Key.ProductName,
                g.Sum(x => x.LineTotal), g.Sum(x => x.Quantity), g.Count()))
            .OrderByDescending(x => x.Amount)
            .Take(take)
            .ToList();
    }

    private async Task<List<TopItemDto>> TopCustomersAsync(
        DateOnly from, DateOnly to, int take, CancellationToken cancellationToken)
    {
        var rows = await _db.Sales
            .Where(s => s.DeletedAt == null && s.BusinessId == BusinessId
                && s.SaleDate >= from && s.SaleDate <= to && s.CustomerId != null)
            .Select(s => new { CustomerId = s.CustomerId!.Value, Name = s.Customer!.Name, s.TotalAmount })
            .ToListAsync(cancellationToken);

        return rows
            .GroupBy(r => new { r.CustomerId, r.Name })
            .Select(g => new TopItemDto(g.Key.CustomerId, g.Key.Name, g.Sum(x => x.TotalAmount), 0, g.Count()))
            .OrderByDescending(x => x.Amount)
            .Take(take)
            .ToList();
    }

    private async Task<List<TrendPointDto>> BuildTrendAsync(
        DateOnly from, DateOnly to, string groupBy, CancellationToken cancellationToken)
    {
        var salesRows = await _db.Sales
            .Where(s => s.DeletedAt == null && s.BusinessId == BusinessId
                && s.SaleDate >= from && s.SaleDate <= to)
            .Select(s => new { s.SaleDate, Net = s.Subtotal - s.DiscountAmount })
            .ToListAsync(cancellationToken);

        var cogsRows = await _db.SaleItems
            .Where(i => i.BusinessId == BusinessId
                && i.Sale.DeletedAt == null
                && i.Sale.SaleDate >= from && i.Sale.SaleDate <= to)
            .Select(i => new { i.Sale.SaleDate, i.Quantity, Cost = i.Product.CostPrice })
            .ToListAsync(cancellationToken);

        var purchaseRows = await _db.Purchases
            .Where(p => p.DeletedAt == null && p.BusinessId == BusinessId
                && p.PurchaseDate >= from && p.PurchaseDate <= to)
            .Select(p => new { p.PurchaseDate, p.TotalAmount })
            .ToListAsync(cancellationToken);

        var expenseRows = await _db.Expenses
            .Where(e => e.DeletedAt == null && e.BusinessId == BusinessId
                && e.ExpenseDate >= from && e.ExpenseDate <= to)
            .Select(e => new { e.ExpenseDate, e.Amount })
            .ToListAsync(cancellationToken);

        var incomeRows = await _db.Incomes
            .Where(i => i.DeletedAt == null && i.BusinessId == BusinessId
                && i.IncomeDate >= from && i.IncomeDate <= to)
            .Select(i => new { i.IncomeDate, i.Amount })
            .ToListAsync(cancellationToken);

        var sales = new Dictionary<DateOnly, long>();
        foreach (var r in salesRows)
            Accumulate(sales, BucketOf(r.SaleDate, groupBy), r.Net);

        var cogs = new Dictionary<DateOnly, long>();
        foreach (var r in cogsRows)
            Accumulate(cogs, BucketOf(r.SaleDate, groupBy),
                (long)Math.Round(r.Cost * r.Quantity, MidpointRounding.AwayFromZero));

        var purchases = SumByBucket(purchaseRows.Select(r => (r.PurchaseDate, r.TotalAmount)), groupBy);
        var expenses = SumByBucket(expenseRows.Select(r => (r.ExpenseDate, r.Amount)), groupBy);
        var income = SumByBucket(incomeRows.Select(r => (r.IncomeDate, r.Amount)), groupBy);

        var points = new List<TrendPointDto>();
        for (var bucket = BucketOf(from, groupBy); bucket <= to; bucket = NextBucket(bucket, groupBy))
        {
            var revenue = sales.GetValueOrDefault(bucket);
            var cost = cogs.GetValueOrDefault(bucket);
            var gross = revenue - cost;
            var expense = expenses.GetValueOrDefault(bucket);
            var other = income.GetValueOrDefault(bucket);

            points.Add(new TrendPointDto(
                bucket, revenue, cost, gross,
                purchases.GetValueOrDefault(bucket), expense, other,
                gross + other - expense));
        }

        return points;
    }

    private static void Accumulate(Dictionary<DateOnly, long> map, DateOnly key, long value)
        => map[key] = map.GetValueOrDefault(key) + value;

    private static Dictionary<DateOnly, long> SumByBucket(
        IEnumerable<(DateOnly Date, long Amount)> rows, string groupBy)
    {
        var map = new Dictionary<DateOnly, long>();
        foreach (var (date, amount) in rows)
            Accumulate(map, BucketOf(date, groupBy), amount);

        return map;
    }

    /// <summary>Bucket start: the day itself, its Monday, or the 1st of the month.</summary>
    private static DateOnly BucketOf(DateOnly date, string groupBy) => groupBy switch
    {
        "week" => date.AddDays(-(((int)date.DayOfWeek + 6) % 7)),
        "month" => new DateOnly(date.Year, date.Month, 1),
        _ => date,
    };

    private static DateOnly NextBucket(DateOnly date, string groupBy) => groupBy switch
    {
        "week" => date.AddDays(7),
        "month" => date.AddMonths(1),
        _ => date.AddDays(1),
    };

    /// <summary>Paisa as a plain decimal string, for spreadsheets.</summary>
    private static string Money(long paisa) =>
        (paisa / 100m).ToString("0.00", CultureInfo.InvariantCulture);

    private static string Csv(IReadOnlyList<string> header, IEnumerable<IReadOnlyList<string>> rows)
    {
        var builder = new StringBuilder();
        builder.AppendLine(string.Join(',', header.Select(Escape)));
        foreach (var row in rows)
            builder.AppendLine(string.Join(',', row.Select(Escape)));

        return builder.ToString();
    }

    private static string Escape(string? value)
    {
        var text = value ?? string.Empty;
        return text.Contains(',') || text.Contains('"') || text.Contains('\n') || text.Contains('\r')
            ? '"' + text.Replace("\"", "\"\"") + '"'
            : text;
    }
}
