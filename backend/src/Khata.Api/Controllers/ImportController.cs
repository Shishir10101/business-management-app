namespace Khata.Api.Controllers;

using System.Text;
using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

/// <summary>
/// Bulk import of a spreadsheet-exported CSV into the active business.
/// </summary>
/// <remarks>
/// <para>
/// Two rules hold for both entities: a row that fails validation refuses the
/// WHOLE file (nothing is written, and the response lists the rows to fix), and
/// rows that already exist are skipped rather than overwritten — so re-running
/// the same file is safe.
/// </para>
/// <para>
/// Money is rupees in the file ("1,234.50", "Rs 1,234.50") and paisa on the
/// wire. Tax is a percentage ("13" or "13%") and basis points on the wire.
/// </para>
/// </remarks>
[ApiController]
[Route("api/import")]
[Authorize]
public class ImportController : ControllerBase
{
    private readonly IImportService _import;

    public ImportController(IImportService import)
    {
        _import = import;
    }

    /// <summary>
    /// Header-only CSV template for the product importer. Open it in Excel,
    /// fill in the rows, save as CSV and import.
    /// </summary>
    [HttpGet("products/template")]
    [Authorize(Policy = Permissions.ImportProducts)]
    [Produces("text/csv")]
    public IActionResult ProductTemplate() => CsvFile(_import.ProductTemplate());

    /// <summary>
    /// Dry run: reports what the file WOULD create, without writing anything.
    /// </summary>
    [HttpPost("products/preview")]
    [Authorize(Policy = Permissions.ImportProducts)]
    [ProducesResponseType(typeof(ImportPreviewDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<ImportPreviewDto>> PreviewProducts([FromBody] ImportRequest request)
        => Ok(await _import.PreviewProductsAsync(request.Csv));

    /// <summary>
    /// Imports products. Returns 422 with the preview (and writes nothing) when
    /// any row is invalid.
    /// </summary>
    [HttpPost("products")]
    [Authorize(Policy = Permissions.ImportProducts)]
    [ProducesResponseType(typeof(ImportResultDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ImportPreviewDto), StatusCodes.Status422UnprocessableEntity)]
    public async Task<ActionResult<ImportResultDto>> ImportProducts([FromBody] ImportRequest request)
        => Outcome(await _import.ImportProductsAsync(request.Csv));

    /// <summary>Header-only CSV template for the customer importer.</summary>
    [HttpGet("customers/template")]
    [Authorize(Policy = Permissions.ImportCustomers)]
    [Produces("text/csv")]
    public IActionResult CustomerTemplate() => CsvFile(_import.CustomerTemplate());

    /// <summary>Dry run for the customer importer.</summary>
    [HttpPost("customers/preview")]
    [Authorize(Policy = Permissions.ImportCustomers)]
    [ProducesResponseType(typeof(ImportPreviewDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<ImportPreviewDto>> PreviewCustomers([FromBody] ImportRequest request)
        => Ok(await _import.PreviewCustomersAsync(request.Csv));

    /// <summary>
    /// Imports customers. A customer with an opening balance gets its ledger
    /// account and opening khata entry, exactly as if it were created by hand.
    /// </summary>
    [HttpPost("customers")]
    [Authorize(Policy = Permissions.ImportCustomers)]
    [ProducesResponseType(typeof(ImportResultDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ImportPreviewDto), StatusCodes.Status422UnprocessableEntity)]
    public async Task<ActionResult<ImportResultDto>> ImportCustomers([FromBody] ImportRequest request)
        => Outcome(await _import.ImportCustomersAsync(request.Csv));

    /// <summary>
    /// 200 with the result, or 422 with the refusal — the client shows the same
    /// preview it saw before importing, so nothing is a surprise.
    /// </summary>
    private ActionResult<ImportResultDto> Outcome(ImportOutcomeDto outcome)
        => outcome.Rejected is not null
            ? UnprocessableEntity(outcome.Rejected)
            : Ok(outcome.Result);

    /// <summary>
    /// UTF-8 with a BOM so Excel opens Devanagari headers correctly (same
    /// convention as the report CSV export).
    /// </summary>
    private FileContentResult CsvFile(CsvExportDto csv)
    {
        var bytes = Encoding.UTF8.GetPreamble()
            .Concat(Encoding.UTF8.GetBytes(csv.Content))
            .ToArray();
        return File(bytes, "text/csv", csv.FileName);
    }
}
