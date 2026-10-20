import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/sync_repository_impl.dart';
import '../../domain/entities/sync_entities.dart';

/// Time of the last completed sync (null until the first sync finishes).
/// Updated by [syncNowProvider] and bootstrapped from disk on page open.
final lastSyncAtProvider = StateProvider<DateTime?>((ref) => null);

/// Operations still waiting in the local push queue.
/// Bumped by callers after `enqueue`, set precisely after each sync cycle.
final pendingCountProvider = StateProvider<int>((ref) => 0);

/// True while a sync cycle (push + pull) is running.
final isSyncingProvider = StateProvider<bool>((ref) => false);

/// Conflicts surfaced by syncs: the server copy is newer than the client's
/// `baseUpdatedAt`, so the local write was not applied and is never
/// overwritten. New conflicts are merged in, not replaced, so unresolved ones
/// stay visible.
final conflictsProvider = StateProvider<List<SyncConflict>>((ref) => const []);

/// Queued operations whose last delivery attempt failed (network errors);
/// they stay in the queue and retry on the next sync.
final failedQueueProvider = FutureProvider<List<QueuedOperation>>((ref) async {
  final ops = await ref.read(syncRepositoryProvider).queuedOperations();
  return ops.where((op) => op.lastError != null).toList();
});

/// Runs one full sync cycle: push queued writes, then pull server changes
/// since the stored cursor and apply them to the local cache.
final syncNowProvider = FutureProvider<SyncOutcome>((ref) async {
  ref.read(isSyncingProvider.notifier).state = true;
  try {
    final outcome = await ref.read(syncRepositoryProvider).syncNow();
    ref.read(lastSyncAtProvider.notifier).state = outcome.serverTime;
    ref.read(pendingCountProvider.notifier).state = outcome.pendingCount;

    // Merge: keep previously surfaced conflicts the user has not resolved.
    final existing = ref.read(conflictsProvider);
    final merged = [
      ...existing.where(
        (old) => !outcome.conflictDetails.any(
          (fresh) =>
              fresh.entityId == old.entityId &&
              fresh.entityType == old.entityType &&
              fresh.operation == old.operation,
        ),
      ),
      ...outcome.conflictDetails,
    ];
    ref.read(conflictsProvider.notifier).state = merged;
    return outcome;
  } finally {
    ref.read(isSyncingProvider.notifier).state = false;
  }
});

/// Re-runs the sync. Skipped while a sync is already in flight.
///
/// Takes a `WidgetRef` because the callers are widgets. A provider holds a
/// `Ref` instead, and the two are unrelated types in Riverpod 2, so
/// [refreshSyncFromRef] mirrors this body for provider-side callers.
void refreshSync(WidgetRef ref) {
  if (ref.read(isSyncingProvider)) return;
  ref.invalidate(syncNowProvider);
  ref.invalidate(failedQueueProvider);
}

/// Provider-side twin of [refreshSync] (a `Ref`, not a `WidgetRef`).
void refreshSyncFromRef(Ref ref) {
  if (ref.read(isSyncingProvider)) return;
  ref.invalidate(syncNowProvider);
  ref.invalidate(failedQueueProvider);
}
