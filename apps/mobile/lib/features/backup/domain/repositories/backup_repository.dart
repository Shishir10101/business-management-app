import '../entities/backup_entities.dart';

/// Business data backup: export a full snapshot, restore one.
abstract class BackupRepository {
  /// Downloads the snapshot as raw JSON bytes.
  Future<List<int>> export();

  /// Restores a snapshot. Merge-only: rows already present are skipped.
  Future<BackupRestoreResult> restore(Map<String, dynamic> payload);
}
