/// Which list a CSV file fills.
enum ImportTarget {
  products,
  customers;

  /// Path segment used by `/api/import/{target}`.
  String get path => name;
}

/// One row-level problem reported by the importer.
///
/// [row] is the line number in the file (the header is row 1), so it matches
/// what the user sees in Excel; [column] is the header that caused it, or null
/// for a problem with the whole row.
class ImportIssue {
  final int row;
  final String? column;
  final String message;

  const ImportIssue({
    required this.row,
    required this.message,
    this.column,
  });

  factory ImportIssue.fromJson(Map<String, dynamic> json) => ImportIssue(
        row: (json['row'] as num?)?.toInt() ?? 0,
        column: json['column'] as String?,
        message: json['message'] as String? ?? '',
      );
}

/// What an import WOULD do. Produced by the preview (dry run) and returned
/// again when the server refuses an import because rows are invalid.
class ImportPreview {
  final String entity;
  final int totalRows;
  final int validRows;
  final int duplicateRows;
  final int invalidRows;

  /// Headers the importer understood, in file order.
  final List<String> columns;

  /// Headers that matched nothing and are being ignored.
  final List<String> ignoredColumns;

  final List<ImportIssue> issues;

  const ImportPreview({
    required this.entity,
    required this.totalRows,
    required this.validRows,
    required this.duplicateRows,
    required this.invalidRows,
    this.columns = const [],
    this.ignoredColumns = const [],
    this.issues = const [],
  });

  /// True when the file cannot be imported until the rows are fixed.
  bool get isBlocked => invalidRows > 0;

  /// True when there is at least one row to write.
  bool get hasSomethingToImport => validRows > 0;

  factory ImportPreview.fromJson(Map<String, dynamic> json) => ImportPreview(
        entity: json['entity'] as String? ?? '',
        totalRows: (json['totalRows'] as num?)?.toInt() ?? 0,
        validRows: (json['validRows'] as num?)?.toInt() ?? 0,
        duplicateRows: (json['duplicateRows'] as num?)?.toInt() ?? 0,
        invalidRows: (json['invalidRows'] as num?)?.toInt() ?? 0,
        columns: _strings(json['columns']),
        ignoredColumns: _strings(json['ignoredColumns']),
        issues: _issues(json['issues']),
      );
}

/// What an import actually did.
class ImportResult {
  final String entity;
  final int created;
  final int skipped;
  final List<ImportIssue> issues;

  const ImportResult({
    required this.entity,
    required this.created,
    required this.skipped,
    this.issues = const [],
  });

  factory ImportResult.fromJson(Map<String, dynamic> json) => ImportResult(
        entity: json['entity'] as String? ?? '',
        created: (json['created'] as num?)?.toInt() ?? 0,
        skipped: (json['skipped'] as num?)?.toInt() ?? 0,
        issues: _issues(json['issues']),
      );
}

/// Either the import ran, or it was refused with a preview — never both.
///
/// A refusal writes nothing: the user fixes the file and tries again.
class ImportOutcome {
  final ImportResult? result;
  final ImportPreview? rejection;

  const ImportOutcome({this.result, this.rejection});

  bool get wasRejected => rejection != null;
}

List<String> _strings(Object? value) => value is List
    ? value.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList()
    : const [];

List<ImportIssue> _issues(Object? value) => value is List
    ? value
        .whereType<Map<String, dynamic>>()
        .map(ImportIssue.fromJson)
        .toList()
    : const [];
