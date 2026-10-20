import '../entities/import_entities.dart';

/// CSV import for the active business.
///
/// The server owns every rule (header aliases, money and tax parsing, duplicate
/// detection, validation). This interface only carries text in and reports out.
abstract class ImportRepository {
  /// Header-only CSV the user can open in Excel.
  Future<String> template(ImportTarget target);

  /// Dry run — nothing is written.
  Future<ImportPreview> preview(ImportTarget target, String csv);

  /// Writes the rows. A file with invalid rows is refused as a whole and comes
  /// back as [ImportOutcome.rejection].
  Future<ImportOutcome> importCsv(ImportTarget target, String csv);
}
