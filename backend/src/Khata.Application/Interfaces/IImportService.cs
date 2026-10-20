namespace Khata.Application.Interfaces;

using Khata.Application.DTOs;

/// <summary>
/// Bulk import of a spreadsheet-exported CSV into the active business.
/// </summary>
/// <remarks>
/// Two rules hold for every import:
/// <list type="bullet">
/// <item>A row that fails validation refuses the WHOLE file — a half-imported
/// catalog is worse than none, and the preview tells the user exactly which
/// rows to fix.</item>
/// <item>Rows that already exist (same SKU, or same name for a customer) are
/// skipped, never overwritten, so re-running the same file is safe.</item>
/// </list>
/// </remarks>
public interface IImportService
{
    Task<ImportPreviewDto> PreviewProductsAsync(string csv, CancellationToken cancellationToken = default);
    Task<ImportOutcomeDto> ImportProductsAsync(string csv, CancellationToken cancellationToken = default);

    Task<ImportPreviewDto> PreviewCustomersAsync(string csv, CancellationToken cancellationToken = default);
    Task<ImportOutcomeDto> ImportCustomersAsync(string csv, CancellationToken cancellationToken = default);

    /// <summary>Header-only CSV, ready to fill in Excel.</summary>
    CsvExportDto ProductTemplate();

    /// <summary>Header-only CSV, ready to fill in Excel.</summary>
    CsvExportDto CustomerTemplate();
}
