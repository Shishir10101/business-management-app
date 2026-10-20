namespace Khata.Application.Interfaces;

using Khata.Application.DTOs;

/// <summary>
/// Business intelligence: the dashboard, the standard reports and CSV exports.
/// Every figure is scoped to the caller's active business and to a date range
/// on the document date (inclusive on both ends).
/// </summary>
public interface IReportService
{
    /// <summary>Today's and this month's KPIs, balances, stock value and trends.</summary>
    Task<DashboardDto> GetDashboardAsync(CancellationToken cancellationToken = default);

    Task<SalesReportDto> GetSalesReportAsync(
        DateOnly dateFrom, DateOnly dateTo, string groupBy, int top,
        CancellationToken cancellationToken = default);

    Task<PurchaseReportDto> GetPurchaseReportAsync(
        DateOnly dateFrom, DateOnly dateTo, string groupBy, int top,
        CancellationToken cancellationToken = default);

    Task<ExpenseReportDto> GetExpenseReportAsync(
        DateOnly dateFrom, DateOnly dateTo, string groupBy,
        CancellationToken cancellationToken = default);

    Task<IncomeReportDto> GetIncomeReportAsync(
        DateOnly dateFrom, DateOnly dateTo, string groupBy,
        CancellationToken cancellationToken = default);

    Task<ProfitLossDto> GetProfitLossAsync(
        DateOnly dateFrom, DateOnly dateTo, CancellationToken cancellationToken = default);

    Task<StockReportDto> GetStockReportAsync(
        bool lowStockOnly, string? search, CancellationToken cancellationToken = default);

    Task<ReceivablePayableReportDto> GetReceivablePayableAsync(
        CancellationToken cancellationToken = default);

    /// <summary>
    /// VAT sales register (IRD Anusuchi 5) for a date range.
    /// </summary>
    Task<VatRegisterDto> GetVatSalesRegisterAsync(
        DateOnly dateFrom, DateOnly dateTo, CancellationToken cancellationToken = default);

    /// <summary>
    /// VAT purchase register (IRD Anusuchi 6) for a date range.
    /// </summary>
    Task<VatRegisterDto> GetVatPurchaseRegisterAsync(
        DateOnly dateFrom, DateOnly dateTo, CancellationToken cancellationToken = default);

    /// <summary>
    /// Outstanding customer balances bucketed by invoice age. The khata records
    /// a due amount rather than a due date, so age is measured from the invoice.
    /// </summary>
    Task<ReceivablesAgingDto> GetReceivablesAgingAsync(
        DateOnly? asOf, CancellationToken cancellationToken = default);

    /// <summary>
    /// Renders one of the reports as CSV. <paramref name="reportType"/> is one of
    /// <c>sales</c>, <c>purchases</c>, <c>expenses</c>, <c>income</c>,
    /// <c>profit-loss</c> or <c>stock</c>.
    /// </summary>
    Task<CsvExportDto> ExportCsvAsync(
        string reportType, DateOnly dateFrom, DateOnly dateTo,
        CancellationToken cancellationToken = default);
}
