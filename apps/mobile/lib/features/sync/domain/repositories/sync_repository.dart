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
}
