import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/sync_entities.dart';
import '../../domain/repositories/sync_repository.dart';
import '../datasources/sync_remote_datasource.dart';
import '../local/local_cache_store.dart';

/// Implementation of SyncRepository against the Khata delta sync protocol.
///
/// Order of operations in [syncNow]:
///  1. GET /sync/status for the server state.
///  2. POST /sync/push for every queued local write. Applied/duplicate
///     operations leave the queue; conflicts are surfaced (never overwritten)
///     and rejections are reported; both drop out of the queue so the same op
///     cannot loop forever.
///  3. GET /sync/pull pages (limit 500) since the stored cursor — a full first
///     pull when there is none — applying each change to the local cache.
///  4. The last response's `serverTime` becomes the new stored cursor.
class SyncRepositoryImpl implements SyncRepository {
  SyncRepositoryImpl(this._remote);

  final SyncRemoteDatasource _remote;
  Future<LocalCacheStore>? _storeFuture;

  /// Lazily creates (and memoizes) the local cache store so concurrent
  /// callers share one instance.
  Future<LocalCacheStore> get _cache =>
      _storeFuture ??= LocalCacheStore.create();

  static const _uuid = Uuid();

  @override
  Future<SyncOutcome> syncNow() async {
    final store = await _cache;

    // 1. Server status (also a cheap reachability check).
    final status = await _remote.getStatus();
    final statusServerTime = DateTime.tryParse(
      status['serverTime'] as String? ?? '',
    );

    // 2. Push the queue first so local writes reach the server before we
    //    pull (the pull could otherwise return stale copies of our own
    //    edits).
    final pushResult = await _pushQueue(store);

    // 3. Pull pages since the stored cursor (full pull when never synced).
    final since = await store.lastServerCursor;
    var cursor = since;
    var pulled = 0;
    while (true) {
      final page = await _remote.pull(since: cursor);
      final changes = (page['changes'] as List<dynamic>?) ?? const [];
      for (final change in changes) {
        if (change is! Map<String, dynamic>) continue;
        await _applyChange(store, change);
      }
      pulled += changes.length;
      final serverTime = page['serverTime'] as String?;
      if (serverTime != null && serverTime.isNotEmpty) cursor = serverTime;
      final hasMore = page['hasMore'] as bool? ?? false;
      if (!hasMore || changes.isEmpty) break;
    }

    await store.setLastServerCursor(cursor);

    // The last page's serverTime is this sync's completion time; it is also
    // the cursor position, so both stay consistent.
    final completedAt =
        DateTime.tryParse(cursor ?? '') ?? statusServerTime ?? DateTime.now();
    await store.setLastSyncAt(completedAt);

    final queued = await store.queuedOperations;
    return SyncOutcome(
      pushed: pushResult.pushed,
      pulled: pulled,
      conflicts: pushResult.conflicts.length,
      rejected: pushResult.rejected,
      conflictDetails: pushResult.conflicts,
      rejections: pushResult.rejections,
      serverTime: completedAt,
      pendingCount: queued.length,
    );
  }

  /// Push result of one cycle.
  Future<_PushResult> _pushQueue(LocalCacheStore store) async {
    final queued = await store.queuedOperations;
    if (queued.isEmpty) {
      return const _PushResult(
          pushed: 0, rejected: 0, conflicts: [], rejections: []);
    }

    final operations = queued
        .map((op) => {
              'operationId': op['operationId'],
              'entityType': op['entityType'],
              'operation': op['operation'],
              'entityId': op['entityId'],
              if (op['baseUpdatedAt'] != null)
                'baseUpdatedAt': op['baseUpdatedAt'],
              if (op['payloadJson'] != null && op['payloadJson'] != '')
                'payload': jsonDecode(op['payloadJson'] as String),
            })
        .toList();

    final Map<String, dynamic> response;
    try {
      response = await _remote.push(operations);
    } catch (error) {
      // Network-level failure: keep every operation queued and bump the
      // attempt counters so the failed list can surface them.
      for (final op in queued) {
        await store.recordAttemptFailure(
          op['operationId'] as String,
          error.toString(),
        );
      }
      rethrow;
    }

    final conflicts = <SyncConflict>[];
    final rejections = <SyncRejection>[];
    var pushed = 0;
    var rejected = 0;

    final results = (response['results'] as List<dynamic>?) ?? const [];
    final byOperationId = {
      for (final op in queued) op['operationId'] as String: op,
    };
    final handled = <String>{};

    for (final raw in results) {
      if (raw is! Map<String, dynamic>) continue;
      final operationId = raw['operationId'] as String? ?? '';
      if (operationId.isEmpty || handled.contains(operationId)) continue;
      handled.add(operationId);
      final op = byOperationId[operationId];
      final status = raw['status'] as String? ?? '';
      final entityId = (raw['entityId'] ?? op?['entityId'] ?? '').toString();
      final entityType = op?['entityType'] as String? ?? '';
      final operation = op?['operation'] as String? ?? '';

      switch (status) {
        case 'applied':
        case 'duplicate':
          pushed++;
          // A create was queued under a temporary id because the server had not
          // seen the record yet. Adopt the id it just assigned, so the cached
          // row and any follow-up update/delete in the queue address the real
          // record. `duplicate` reports the same id (the ledger remembers it),
          // which also repairs a client that crashed before it could remap.
          final serverId = (raw['entityId'] ?? '').toString();
          final localId = (op?['entityId'] ?? '').toString();
          if (operation == 'create' &&
              localId.isNotEmpty &&
              serverId.isNotEmpty &&
              serverId != localId) {
            await store.remapEntityId(entityType, localId, serverId);
          }
          await store.removeOperation(operationId);
          break;
        case 'conflict':
          final version = raw['version'];
          final changedAtRaw = raw['changedAt'] ??
              (version is Map<String, dynamic> ? version['updatedAt'] : null);
          conflicts.add(SyncConflict(
            entityType: entityType,
            entityId: entityId,
            operation: operation,
            serverVersion: version is Map<String, dynamic>
                ? version
                : (raw['payload'] is Map<String, dynamic>
                    ? raw['payload'] as Map<String, dynamic>
                    : null),
            serverChangedAt: DateTime.tryParse(changedAtRaw?.toString() ?? ''),
            message: raw['error'] as String?,
          ));
          // A conflict means the server copy is newer: surface it, never
          // overwrite. Drop it from the queue so it cannot loop forever;
          // it stays visible via the persisted conflicts list.
          await store.removeOperation(operationId);
          break;
        case 'rejected':
          rejected++;
          rejections.add(SyncRejection(
            operationId: operationId,
            entityType: entityType,
            entityId: entityId,
            error: raw['error'] as String?,
          ));
          await store.removeOperation(operationId);
          break;
        default:
          // Unknown status: leave the operation queued for a later attempt.
          break;
      }
    }

    // The response's dedicated `conflicts` array may carry richer detail than
    // the per-operation results; merge anything not already reported.
    final rawConflicts = (response['conflicts'] as List<dynamic>?) ?? const [];
    for (final raw in rawConflicts) {
      if (raw is! Map<String, dynamic>) continue;
      final entityId = (raw['entityId'] ?? '').toString();
      final already = conflicts.any(
        (c) => c.entityId == entityId && c.entityType == raw['entityType'],
      );
      if (!already) {
        conflicts.add(SyncConflict(
          entityType: raw['entityType'] as String? ?? '',
          entityId: entityId,
          operation: raw['operation'] as String? ?? '',
          serverVersion: raw['payload'] is Map<String, dynamic>
              ? raw['payload'] as Map<String, dynamic>
              : (raw['serverVersion'] is Map<String, dynamic>
                  ? raw['serverVersion'] as Map<String, dynamic>
                  : null),
          serverChangedAt: DateTime.tryParse(
            raw['changedAt'] as String? ?? '',
          ),
          message: raw['error'] as String?,
        ));
      }
    }

    await store.setConflicts(conflicts.map((c) => c.toJson()).toList());

    return _PushResult(
      pushed: pushed,
      rejected: rejected,
      conflicts: conflicts,
      rejections: rejections,
    );
  }

  Future<void> _applyChange(
    LocalCacheStore store,
    Map<String, dynamic> change,
  ) async {
    final entityType = change['entityType'] as String? ?? '';
    final entityId = (change['entityId'] ?? '').toString();
    final changeType = change['changeType'] as String? ?? 'upsert';
    if (entityType.isEmpty || entityId.isEmpty) return;

    if (changeType == 'deleted') {
      await store.markDeleted(entityType, entityId);
      return;
    }
    final payload = change['payload'];
    if (payload is Map<String, dynamic>) {
      await store.upsert(entityType, {
        ...payload,
        'id': payload['id'] ?? entityId,
      });
    }
  }

  @override
  Future<SyncOperationHandle> enqueue({
    required String entityType,
    required String operation,
    required String entityId,
    Map<String, dynamic>? payload,
    DateTime? baseUpdatedAt,
  }) async {
    final store = await _cache;
    final operationId = _uuid.v4();
    await store.enqueueOperation({
      'operationId': operationId,
      'entityType': entityType,
      'operation': operation,
      'entityId': entityId,
      if (baseUpdatedAt != null)
        'baseUpdatedAt': baseUpdatedAt.toIso8601String(),
      'payloadJson': payload == null ? '' : jsonEncode(payload),
      'createdAt': DateTime.now().toIso8601String(),
      'attempts': 0,
    });
    return SyncOperationHandle(
      operationId: operationId,
      entityType: entityType,
      entityId: entityId,
      operation: operation,
    );
  }

  @override
  Future<List<QueuedOperation>> queuedOperations() async {
    final store = await _cache;
    final raw = await store.queuedOperations;
    return raw
        .map((op) => QueuedOperation(
              operationId: op['operationId'] as String,
              entityType: op['entityType'] as String? ?? '',
              operation: op['operation'] as String? ?? 'update',
              entityId: (op['entityId'] ?? '').toString(),
              payload: op['payloadJson'] is String &&
                      (op['payloadJson'] as String).isNotEmpty
                  ? (jsonDecode(op['payloadJson'] as String)
                      as Map<String, dynamic>)
                  : const {},
              baseUpdatedAt: DateTime.tryParse(
                op['baseUpdatedAt'] as String? ?? '',
              ),
              createdAt: DateTime.tryParse(
                    op['createdAt'] as String? ?? '',
                  ) ??
                  DateTime.now(),
              attempts: (op['attempts'] as num?)?.toInt() ?? 0,
              lastError: op['lastError'] as String?,
            ))
        .toList();
  }

  @override
  Future<List<SyncConflict>> persistedConflicts() async {
    final store = await _cache;
    final raw = await store.conflicts;
    return raw.map(SyncConflict.fromJson).toList();
  }

  @override
  Future<DateTime?> lastSyncAt() async {
    final store = await _cache;
    return store.lastSyncAt;
  }
}

/// Internal result of pushing the queue in one cycle.
class _PushResult {
  final int pushed;
  final int rejected;
  final List<SyncConflict> conflicts;
  final List<SyncRejection> rejections;

  const _PushResult({
    required this.pushed,
    required this.rejected,
    required this.conflicts,
    required this.rejections,
  });
}

/// Provider for the sync repository implementation.
final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return SyncRepositoryImpl(ref.read(syncRemoteDatasourceProvider));
});
