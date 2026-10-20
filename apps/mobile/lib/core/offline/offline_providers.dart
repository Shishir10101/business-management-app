import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/sync/data/repositories/sync_repository_impl.dart';
import '../../features/sync/presentation/providers/sync_providers.dart';
import '../network/dio_client.dart';
import 'cached_reader.dart';
import 'offline_queue.dart';
import 'snapshot_cache.dart';

/// The persistent snapshot cache used by list screens.
///
/// One instance for the app: the file is loaded once and shared, so concurrent
/// reads cannot interleave writes.
final snapshotCacheProvider = Provider<SnapshotCache>((ref) {
  return SnapshotCache(directory: getApplicationDocumentsDirectory);
});

/// Cache namespace of the signed-in session (business + user, from the JWT).
final snapshotScopeProvider = Provider<SnapshotScope>((ref) {
  final storage = ref.read(secureStorageProvider);
  return SnapshotScope(() => storage.read(key: 'access_token'));
});

/// Groups whose last read was served from the cache, and when that copy was
/// saved. A group is one screen's data set ('products', 'customers', …).
class CachedReadNotifier extends StateNotifier<Map<String, DateTime>> {
  CachedReadNotifier() : super(const {});

  void mark(String group, DateTime savedAt) {
    if (state[group] == savedAt) return;
    state = {...state, group: savedAt};
  }

  void clearGroup(String group) {
    if (!state.containsKey(group)) return;
    state = {...state}..remove(group);
  }

  void clearAll() {
    if (state.isEmpty) return;
    state = const {};
  }
}

final cachedReadProvider =
    StateNotifierProvider<CachedReadNotifier, Map<String, DateTime>>(
  (ref) => CachedReadNotifier(),
);

/// Builds a reader wired to [cachedReadProvider], for a repository provider.
CachedReader cachedReaderFor(Ref ref) {
  return CachedReader(
    cache: ref.read(snapshotCacheProvider),
    scope: ref.read(snapshotScopeProvider).resolve,
    onResult: (group, savedAt) {
      final notifier = ref.read(cachedReadProvider.notifier);
      if (savedAt == null) {
        notifier.clearGroup(group);
      } else {
        notifier.mark(group, savedAt);
      }
    },
  );
}

/// What is currently saved on the device, for the sync screen.
class SnapshotStats {
  final int lists;
  final int bytes;
  final bool persistent;

  const SnapshotStats({
    required this.lists,
    required this.bytes,
    required this.persistent,
  });
}

/// Reads the cache on every visit, so the count is never stale after a list
/// screen has filled it.
final snapshotStatsProvider =
    FutureProvider.autoDispose<SnapshotStats>((ref) async {
  final cache = ref.read(snapshotCacheProvider);
  final keys = await cache.keys();
  return SnapshotStats(
    lists: keys.length,
    bytes: cache.sizeInBytes,
    persistent: cache.isPersistent,
  );
});

/// Drops every saved list (a privacy control as much as a size one).
Future<void> clearSnapshotCache(WidgetRef ref) async {
  await ref.read(snapshotCacheProvider).clear();
  ref.read(cachedReadProvider.notifier).clearAll();
  ref.invalidate(snapshotStatsProvider);
}

/// The write-side companion of [cachedReaderFor]: a queue wired to the sync
/// repository, so a save that cannot reach the server is kept for the next sync
/// instead of failing.
///
/// This is the one place where the offline layer is composed with the sync
/// feature — the same way `core/router` composes the feature pages. Everything
/// else in `core/offline` stays independent of it (and free of Flutter, so it
/// can be run by the `tool/verify_*.dart` harnesses).
final offlineQueueProvider = Provider<OfflineQueue>((ref) {
  return OfflineQueue(
    enqueue: ({
      required String entityType,
      required String operation,
      required String entityId,
      Map<String, dynamic>? payload,
      DateTime? baseUpdatedAt,
    }) async {
      await ref.read(syncRepositoryProvider).enqueue(
            entityType: entityType,
            operation: operation,
            entityId: entityId,
            payload: payload,
            baseUpdatedAt: baseUpdatedAt,
          );
      final pending = ref.read(pendingCountProvider);
      ref.read(pendingCountProvider.notifier).state = pending + 1;
    },
  );
});
