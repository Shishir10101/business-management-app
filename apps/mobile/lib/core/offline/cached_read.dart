import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import 'snapshot_cache.dart';

/// Outcome of a cache-first read: the data, and whether it came from disk
/// because the network failed.
class CachedRead<T> {
  const CachedRead(
    this.data, {
    this.fromCache = false,
    this.savedAt,
    this.networkError,
  });

  final T data;

  /// True when [data] is the saved copy, not a fresh server answer.
  final bool fromCache;

  /// When the saved copy was written (only set when [fromCache]).
  final DateTime? savedAt;

  /// The failure that forced the fallback (only set when [fromCache]).
  final Object? networkError;
}

/// Fetches, caches the answer, and falls back to the last cached copy when the
/// request fails for a network reason.
///
/// A server *rejection* (4xx: bad request, unauthorized, not found) is NOT a
/// network failure — falling back would hide a real problem, so it rethrows.
Future<CachedRead<T>> readThroughCache<T>({
  required SnapshotCache cache,
  required String key,
  required Future<T> Function() fetch,
  bool Function(Object error)? shouldFallBack,
}) async {
  try {
    final data = await fetch();
    await cache.write(key, data);
    return CachedRead<T>(data);
  } catch (error) {
    final fallBack = (shouldFallBack ?? isOfflineError)(error);
    if (!fallBack) rethrow;

    final snapshot = await cache.read(key);
    if (snapshot == null) rethrow;

    final cached = snapshot.json;
    // A snapshot written by a different shape of the same key (an app version
    // change) is a miss, not a crash.
    if (cached is! T) rethrow;

    return CachedRead<T>(
      cached,
      fromCache: true,
      savedAt: snapshot.savedAt,
      networkError: error,
    );
  }
}

/// True when the failure means "the network is not there" rather than "the
/// server said no".
bool isOfflineError(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    // No response at all = connection refused/timeout/DNS. A 5xx means the
    // server is reachable but broken, which is also worth showing stale data for.
    if (status == null) return true;
    return status >= 500;
  }
  return error is SocketException || error is TimeoutException || error is HttpException;
}
