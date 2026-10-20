namespace Khata.Api.Controllers;

using System.Text;
using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

/// <summary>Dashboard, standard reports and CSV exports.</summary>
[ApiController]
[Route("api/reports")]
[Authorize]
public class ReportsController : ControllerBase
{
    private readonly IReportService _reports;
    private readonly IDateTimeProvider _clock;

    public ReportsController(IReportService reports, IDateTimeProvider clock)
    {
        _reports = reports;
        _clock = clock;
    }

    /// <summary>Home dashboard: today/month KPIs, balances, stock value, trend.</summary>
    [HttpGet("dashboard")]
    [Authorize(Policy = Permissions.ReportsView)]
    [ProducesResponseType(typeof(DashboardDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<DashboardDto>> GetDashboard()
        => Ok(await _reports.GetDashboardAsync());

    [HttpGet("sales")]
    [Authorize(Policy = Permissions.ReportsView)]
    [ProducesResponseType(typeof(SalesReportDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status422UnprocessableEntity)]
    public async Task<ActionResult<SalesReportDto>> GetSales(
        [FromQuery] DateOnly? dateFrom,
        [FromQuery] DateOnly? dateTo,
        [FromQuery] string groupBy = "day",
        [FromQuery] int top = 10)
    {
        var (from, to) = ResolveRange(dateFrom, dateTo);
        return Ok(await _reports.GetSalesReportAsync(from, to, groupBy, top));
    }

    [HttpGet("purchases")]
    [Authorize(Policy = Permissions.ReportsView)]
    [ProducesResponseType(typeof(PurchaseReportDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<PurchaseReportDto>> GetPurchases(
        [FromQuery] DateOnly? dateFrom,
        [FromQuery] DateOnly? dateTo,
        [FromQuery] string groupBy = "day",
        [FromQuery] int top = 10)
    {
        var (from, to) = ResolveRange(dateFrom, dateTo);
        return Ok(await _reports.GetPurchaseReportAsync(from, to, groupBy, top));
    }

    [HttpGet("expenses")]
    [Authorize(Policy = Permissions.ReportsView)]
    [ProducesResponseType(typeof(ExpenseReportDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<ExpenseReportDto>> GetExpenses(
        [FromQuery] DateOnly? dateFrom,
        [FromQuery] DateOnly? dateTo,
        [FromQuery] string groupBy = "day")
    {
        var (from, to) = ResolveRange(dateFrom, dateTo);
        return Ok(await _reports.GetExpenseReportAsync(from, to, groupBy));
    }

    [HttpGet("income")]
    [Authorize(Policy = Permissions.ReportsView)]
    [ProducesResponseType(typeof(IncomeReportDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<IncomeReportDto>> GetIncome(
        [FromQuery] DateOnly? dateFrom,
        [FromQuery] DateOnly? dateTo,
        [FromQuery] string groupBy = "day")
    {
        var (from, to) = ResolveRange(dateFrom, dateTo);
        return Ok(await _reports.GetIncomeReportAsync(from, to, groupBy));
    }

    /// <summary>Profit &amp; loss. Revenue is net of discounts and excludes tax.</summary>
    [HttpGet("profit-loss")]
    [Authorize(Policy = Permissions.ReportsView)]
    [ProducesResponseType(typeof(ProfitLossDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<ProfitLossDto>> GetProfitLoss(
        [FromQuery] DateOnly? dateFrom,
        [FromQuery] DateOnly? dateTo)
    {
        var (from, to) = ResolveRange(dateFrom, dateTo);
        return Ok(await _reports.GetProfitLossAsync(from, to));
    }

    /// <summary>Stock valuation (cost and retail) per product.</summary>
    [HttpGet("stock")]
    [Authorize(Policy = Permissions.ReportsView)]
    [ProducesResponseType(typeof(StockReportDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<StockReportDto>> GetStock(
        [FromQuery] bool lowStockOnly = false,
        [FromQuery] string? search = null)
        => Ok(await _reports.GetStockReportAsync(lowStockOnly, search));

    /// <summary>Party-wise receivables and payables, largest first.</summary>
    [HttpGet("receivable-payable")]
    [Authorize(Policy = Permissions.ReportsView)]
    [ProducesResponseType(typeof(ReceivablePayableReportDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<ReceivablePayableReportDto>> GetReceivablePayable()
        => Ok(await _reports.GetReceivablePayableAsync());

    /// <summary>VAT sales register (Anusuchi 5). Defaults to current month.</summary>
    [HttpGet("vat-register/sales")]
    [Authorize(Policy = Permissions.ReportsView)]
    [ProducesResponseType(typeof(VatRegisterDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<VatRegisterDto>> GetVatSalesRegister(
        [FromQuery] DateOnly? dateFrom, [FromQuery] DateOnly? dateTo)
    {
        var (from, to) = ResolveRange(dateFrom, dateTo);
        return Ok(await _reports.GetVatSalesRegisterAsync(from, to));
    }

    /// <summary>VAT purchase register (Anusuchi 6). Defaults to current month.</summary>
    [HttpGet("vat-register/purchases")]
    [Authorize(Policy = Permissions.ReportsView)]
    [ProducesResponseType(typeof(VatRegisterDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<VatRegisterDto>> GetVatPurchaseRegister(
        [FromQuery] DateOnly? dateFrom, [FromQuery] DateOnly? dateTo)
    {
        var (from, to) = ResolveRange(dateFrom, dateTo);
        return Ok(await _reports.GetVatPurchaseRegisterAsync(from, to));
    }

    /// <summary>Receivables aging: open balances bucketed by invoice age.</summary>
    [HttpGet("receivables-aging")]
    [Authorize(Policy = Permissions.ReportsView)]
    [ProducesResponseType(typeof(ReceivablesAgingDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<ReceivablesAgingDto>> GetReceivablesAging(
        [FromQuery] DateOnly? asOf = null)
        => Ok(await _reports.GetReceivablesAgingAsync(asOf));

    /// <summary>
    /// Downloads a report as CSV. <paramref name="type"/> is one of
    /// <c>sales</c>, <c>purchases</c>, <c>expenses</c>, <c>income</c>,
    /// <c>profit-loss</c>, <c>stock</c>.
    /// </summary>
    [HttpGet("export")]
    [Authorize(Policy = Permissions.ReportsExport)]
    [Produces("text/csv")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status422UnprocessableEntity)]
    public async Task<IActionResult> Export(
        [FromQuery] string type,
        [FromQuery] DateOnly? dateFrom,
        [FromQuery] DateOnly? dateTo)
    {
        var (from, to) = ResolveRange(dateFrom, dateTo);
        var csv = await _reports.ExportCsvAsync(type, from, to);

        // UTF-8 BOM so Excel opens Nepali text and the ₹-free numerals correctly.
        var bytes = Encoding.UTF8.GetPreamble().Concat(Encoding.UTF8.GetBytes(csv.Content)).ToArray();
        return File(bytes, "text/csv", csv.FileName);
    }

    /// <summary>Defaults to the current month when the range is omitted.</summary>
    private (DateOnly From, DateOnly To) ResolveRange(DateOnly? dateFrom, DateOnly? dateTo)
    {
        var today = _clock.Today;
        var from = dateFrom ?? new DateOnly(today.Year, today.Month, 1);
        var to = dateTo ?? today;
        return (from, to);
    }
}
