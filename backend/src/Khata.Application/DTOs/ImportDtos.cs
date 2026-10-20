namespace Khata.Application.DTOs;

/// <summary>Raw CSV text to import (the whole file, as a string).</summary>
/// <remarks>
/// The body is JSON rather than <c>text/csv</c> on purpose: it keeps the
/// endpoint on the same content-type contract as every other API action, and
/// the client already holds the text (pasted or read off the device) before it
/// calls.
/// </remarks>
public record ImportRequest(string Csv);

/// <summary>One row-level problem found while validating an import file.</summary>
/// <param name="Row">
/// 1-based line number in the file — the header is row 1, so the first data row
/// is row 2, which is what a spreadsheet shows.
/// </param>
/// <param name="Column">The offending column's header, or null for a row-wide problem.</param>
public record ImportIssueDto(int Row, string? Column, string Message);

/// <summary>
/// Dry-run report: what an import WOULD do. Shown before anything is written,
/// and returned with HTTP 422 when an import is refused because rows are invalid.
/// </summary>
/// <param name="Columns">Headers that were understood, in file order.</param>
/// <param name="IgnoredColumns">Headers that matched nothing and will be skipped.</param>
public record ImportPreviewDto(
    string Entity,
    int TotalRows,
    int ValidRows,
    int DuplicateRows,
    int InvalidRows,
    IReadOnlyList<string> Columns,
    IReadOnlyList<string> IgnoredColumns,
    IReadOnlyList<ImportIssueDto> Issues);

/// <summary>What an import actually did.</summary>
/// <param name="Skipped">Rows that matched an existing record and were left alone.</param>
public record ImportResultDto(
    string Entity,
    int Created,
    int Skipped,
    IReadOnlyList<ImportIssueDto> Issues);

/// <summary>
/// Outcome of an import attempt: either it ran (<see cref="Result"/>) or it was
/// refused because the file had invalid rows (<see cref="Rejected"/>) — never
/// both. A refused import writes nothing.
/// </summary>
public record ImportOutcomeDto(ImportResultDto? Result, ImportPreviewDto? Rejected);
