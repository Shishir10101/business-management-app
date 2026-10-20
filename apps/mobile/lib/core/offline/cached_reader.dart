import 'dart:convert';

import 'cached_read.dart';
import 'snapshot_cache.dart';

/// Reads a repository query through the snapshot cache.
///
/// The key is namespaced by the signed-in tenant, so a list cached in one
/// business can never be served in another. When the tenant cannot be
/// determined (no token yet, or an unreadable one) nothing is cached at all —
/// the read simply goes to the network.
class CachedReader {
  CachedReader({
    required this.cache,
    required this.scope,
    required this.onResult,
  });

  /// Tenant prefix used when the session is unknown: no caching happens.
  static const String anonymous = 'anon';

  final SnapshotCache cache;

  /// Resolves the current tenant namespace. Called per read (not cached here)
  /// so a business switch takes effect immediately.
  final Future<String> Function() scope;

  /// Called after every read: `savedAt == null` means the data is fresh, so the
  /// UI can drop its "showing saved data" note.
  final void Function(String group, DateTime? savedAt) onResult;

  Future<T> read<T>({
    required String group,
    required String key,
    required Future<T> Function() fetch,
  }) async {
    final tenant = await _tenant();
    if (tenant == anonymous) return fetch();

    final result = await readThroughCache<T>(
      cache: cache,
      key: '$tenant:$group:$key',
      fetch: fetch,
    );
    onResult(group, result.fromCache ? result.savedAt : null);
    return result.data;
  }

  Future<String> _tenant() async {
    try {
      return await scope();
    } catch (_) {
      return anonymous;
    }
  }
}

/// Derives the cache namespace from the access token.
///
/// The JWT payload's `bid` (active business) and `sub` (user) are exactly what
/// the server scopes every query by, so they are the right partition key. The
/// token is only *read* here — authorization is still the server's job — so an
/// unverified decode is harmless: a tampered token just produces a cache miss.
class SnapshotScope {
  SnapshotScope(this._readToken);

  final Future<String?> Function() _readToken;

  String? _token;
  String _scope = CachedReader.anonymous;

  Future<String> resolve() async {
    final token = await _readToken();
    if (token == _token) return _scope;

    _token = token;
    _scope = token == null ? CachedReader.anonymous : fromToken(token);
    return _scope;
  }

  /// `b<business>-u<user>`, or [CachedReader.anonymous] when it cannot be read.
  static String fromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return CachedReader.anonymous;

      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map) return CachedReader.anonymous;

      final business = payload['bid'];
      final user = payload['sub'] ?? payload['nameid'] ?? '';
      return 'b${business ?? 0}-u$user';
    } catch (_) {
      return CachedReader.anonymous;
    }
  }
}
