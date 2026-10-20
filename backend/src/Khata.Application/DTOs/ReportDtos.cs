namespace Khata.Application.DTOs;

// ==============================================================
// Shared shapes
// ==============================================================

/// <summary>Aggregated money totals for a set of documents (all paisa).</summary>
public record AmountSummaryDto(
    int Count,
    long Subtotal,
    long Discount,
    long Tax,
    long Total,
    long Paid,
    long Due
);

/// <summary>
/// One point of a trend series. Dates are the bucket start (a day, the Monday
/// of a week, or the 1st of a month).
/// </summary>
public record TrendPointDto(
    DateOnly Date,
    long Sales,
    long CostOfGoods,
    long GrossProfit,
    long Purchases,
    long Expenses,
    long Income,
    long NetProfit
);

/// <summary>A ranked row (top product, top customer, top supplier).</summary>
public record TopItemDto(
    long Id,
    string Name,
    long Amount,
    decimal Quantity,
    int Count
);

public record CategoryAmountDto(string Category, long Amount, int Count);

/// <summary>A generated CSV file ready to download.</summary>
public record CsvExportDto(string FileName, string Content);

// ==============================================================
// Dashboard
// ==============================================================

/// <summary>
/// The home dashboard: today's and this month's figures, the balance position,
/// stock value, a 14-day trend and the month's best sellers.
/// </summary>
public record DashboardDto(
    DateOnly AsOf,
    AmountSummaryDto TodaySales,
    AmountSummaryDto MonthSales,
    long TodayPurchases,
    long TodayExpenses,
    long TodayIncome,
    long TodayGrossProfit,
    long TodayNetProfit,
    long MonthPurchases,
    long MonthExpenses,
    long MonthIncome,
    long MonthGrossProfit,
    long MonthNetProfit,
    long TotalReceivable,
    long TotalPayable,
    long CustomerAdvances,
    long SupplierAdvances,
    long StockCostValue,
    long StockRetailValue,
    int LowStockCount,
    int ProductCount,
    int CustomerCount,
    IReadOnlyList<TrendPointDto> Trend,
    IReadOnlyList<TopItemDto> TopProducts,
    IReadOnlyList<TopItemDto> TopCustomers
);

// ==============================================================
// Reports
// ==============================================================

public record SalesReportDto(
    DateOnly DateFrom,
    DateOnly DateTo,
    string GroupBy,
    AmountSummaryDto Totals,
    IReadOnlyList<TrendPointDto> Series,
    IReadOnlyList<TopItemDto> TopProducts,
    IReadOnlyList<TopItemDto> TopCustomers
);

public record PurchaseReportDto(
    DateOnly DateFrom,
    DateOnly DateTo,
    string GroupBy,
    AmountSummaryDto Totals,
    IReadOnlyList<TrendPointDto> Series,
    IReadOnlyList<TopItemDto> TopSuppliers
);

public record ExpenseReportDto(
    DateOnly DateFrom,
    DateOnly DateTo,
    string GroupBy,
    long Total,
    int Count,
    IReadOnlyList<CategoryAmountDto> ByCategory,
    IReadOnlyList<TrendPointDto> Series
);

public record IncomeReportDto(
    DateOnly DateFrom,
    DateOnly DateTo,
    string GroupBy,
    long Total,
    int Count,
    IReadOnlyList<CategoryAmountDto> BySource,
    IReadOnlyList<TrendPointDto> Series
);

/// <summary>
/// Profit &amp; loss. Revenue is net of discounts and **excludes VAT/tax**
/// (tax is collected on the government's behalf). Cost of goods uses each
/// product's current cost price.
/// </summary>
public record ProfitLossDto(
    DateOnly DateFrom,
    DateOnly DateTo,
    long Revenue,
    long CostOfGoods,
    long GrossProfit,
    long OtherIncome,
    long Expenses,
    long NetProfit,
    long SalesTaxCollected,
    IReadOnlyList<CategoryAmountDto> ExpensesByCategory
);

public record StockReportRowDto(
    long ProductId,
    string Name,
    string? CategoryName,
    string? UnitShortName,
    decimal Quantity,
    long CostPrice,
    long SellingPrice,
    long CostValue,
    long RetailValue,
    bool IsLowStock
);

public record StockReportDto(
    long TotalCostValue,
    long TotalRetailValue,
    long PotentialMargin,
    int ProductCount,
    int LowStockCount,
    IReadOnlyList<StockReportRowDto> Items
);

/// <summary>A party with an outstanding balance in one direction.</summary>
public record OutstandingPartyDto(
    long PartyId,
    string Name,
    string? PhoneNumber,
    long Balance,
    int OpenDocuments
);

public record ReceivablePayableReportDto(
    long TotalReceivable,
    long TotalPayable,
    long CustomerAdvances,
    long SupplierAdvances,
    IReadOnlyList<OutstandingPartyDto> Receivables,
    IReadOnlyList<OutstandingPartyDto> Payables
);
