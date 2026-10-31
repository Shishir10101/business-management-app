import '../entities/sync_entities.dart';

/// Offline-first sync against the Khata delta sync protocol.
abstract class SyncRepository {
  /// Pushes queued local writes, then pulls server changes since the stored
  /// cursor and applies them to the local cache.
  Future<SyncOutcome> syncNow();

  /// Queues a local write with a client-generated operation id. The write
  /// reaches the server on the next [syncNow] (or when connectivity returns).
  Future<SyncOperationHandle> enqueue({
    required String entityType,
    required String operation,
    required String entityId,
    Map<String, dynamic>? payload,
    DateTime? baseUpdatedAt,
  });

  /// Operations still waiting in the local queue.
  Future<List<QueuedOperation>> queuedOperations();

  /// Conflicts surfaced by earlier syncs, persisted on device.
  Future<List<SyncConflict>> persistedConflicts();

  /// Last successful sync time, if any.
  Future<DateTime?> lastSyncAt();

  /// Deletes the cached records, the pending queue and the sync cursor.
  ///
  /// Called on sign-out. The cache is a plaintext JSON snapshot of a whole
  /// ledger and it is not keyed by user or business, so leaving it behind would
  /// hand the next account on a shared shop phone the previous tenant's data.
  ///
  /// Anything still queued is dropped with it: a queued write carries the id of
  /// the tenant that created it, so replaying it under another session would
  /// push one business's data into another's.
  Future<void> clearCache();
}
