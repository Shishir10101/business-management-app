import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/import_entities.dart';
import '../../domain/repositories/import_repository.dart';
import '../datasources/import_remote_datasource.dart';

/// ImportRepository backed by the Khata API.
class ImportRepositoryImpl implements ImportRepository {
  ImportRepositoryImpl(this._remote);

  final ImportRemoteDatasource _remote;

  @override
  Future<String> template(ImportTarget target) => _remote.template(target.path);

  @override
  Future<ImportPreview> preview(ImportTarget target, String csv) async =>
      ImportPreview.fromJson(await _remote.preview(target.path, csv));

  @override
  Future<ImportOutcome> importCsv(ImportTarget target, String csv) async {
    final response = await _remote.importCsv(target.path, csv);
    if (response.status == 422) {
      return ImportOutcome(
        rejection: ImportPreview.fromJson(response.body),
      );
    }
    return ImportOutcome(result: ImportResult.fromJson(response.body));
  }
}

/// Provider for the import repository implementation.
final importRepositoryProvider = Provider<ImportRepository>((ref) {
  return ImportRepositoryImpl(ref.read(importRemoteDatasourceProvider));
});
