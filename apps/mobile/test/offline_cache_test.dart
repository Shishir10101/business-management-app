import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:khata/core/offline/cached_read.dart';
import 'package:khata/core/offline/cached_reader.dart';
import 'package:khata/core/offline/snapshot_cache.dart';

/// The offline read layer: the persistent snapshot cache, the cache-first read,
/// and the tenant scoping that keeps one business's data out of another's.
///
/// `tool/verify_offline_cache.dart` runs the same scenarios as a plain Dart
/// program, because `flutter test` cannot start in this environment; this file
/// is the version that runs on a normal machine.
void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('khata_offline_test_'));
  tearDown(() {
    try {
      root.deleteSync(recursive: true);
    } catch (_) {}
  });

  SnapshotCache cacheIn(String name, {int maxEntries = 24, int maxBytes = 3 * 1024 * 1024}) {
    final dir = Directory('${root.path}/$name')..createSync(recursive: true);
    return SnapshotCache(
      directory: () async => dir,
      maxEntries: maxEntries,
      maxBytes: maxBytes,
    );
  }

  group('SnapshotCache', () {
    test('round-trips a payload and survives a new instance', () async {
      final cache = cacheIn('round-trip');
      await cache.write('k', {
        'data': [
          {'id': 1, 'name': 'Rice'},
        ],
      });

      final snapshot = await cache.read('k');
      expect(snapshot, isNotNull);
      expect(((snapshot!.json as Map)['data'] as List), hasLength(1));

      final reopened = cacheIn('round-trip');
      expect(await reopened.read('k'), isNotNull);
    });

    test('evicts the least recently used entry past maxEntries', () async {
      final cache = cacheIn('evict', maxEntries: 3);
      for (var i = 0; i < 5; i++) {
        await cache.write('k$i', {'i': i});
      }

      expect(cache.length, 3);
      expect(await cache.keys(), contains('k4'));
      expect(await cache.keys(), isNot(contains('k0')));
    });

    test('stays inside the byte budget', () async {
      final cache = cacheIn('bytes', maxEntries: 50, maxBytes: 400);
      for (var i = 0; i < 20; i++) {
        await cache.write('big$i', {'padding': 'x' * 40, 'i': i});
      }

      expect(cache.sizeInBytes, lessThanOrEqualTo(400));
      expect(cache.length, greaterThanOrEqualTo(1));
    });

    test('treats a corrupt file as a miss and recovers', () async {
      final dir = Directory('${root.path}/corrupt')..createSync(recursive: true);
      File('${dir.path}/khata_snapshots.json').writeAsStringSync('{not json');
      final cache = SnapshotCache(directory: () async => dir);

      expect(await cache.read('k'), isNull);
      await cache.write('k', {'ok': true});
      expect(await cache.read('k'), isNotNull);
    });

    test('degrades to memory when there is no directory', () async {
      final cache = SnapshotCache(
        directory: () async => throw const FileSystemException('no directory'),
      );

      expect(await cache.read('k'), isNull);
      await cache.write('k', {'ok': true});
      expect(await cache.read('k'), isNotNull);
      expect(cache.isPersistent, isFalse);
    });

    test('clear empties the cache and the file', () async {
      final cache = cacheIn('clear');
      await cache.write('k', {'ok': true});
      await cache.clear();

      expect(await cache.keys(), isEmpty);
      expect(await cacheIn('clear').keys(), isEmpty);
    });
  });

  group('readThroughCache', () {
    test('caches a successful read', () async {
      final cache = cacheIn('fresh');
      final result = await readThroughCache<Map<String, dynamic>>(
        cache: cache,
        key: 'k',
        fetch: () async => {'value': 1},
      );

      expect(result.fromCache, isFalse);
      expect(await cache.read('k'), isNotNull);
    });

    test('falls back to the saved copy when the network fails', () async {
      final cache = cacheIn('fallback');
      await readThroughCache<Map<String, dynamic>>(
        cache: cache,
        key: 'k',
        fetch: () async => {'value': 1},
      );

      final offline = await readThroughCache<Map<String, dynamic>>(
        cache: cache,
        key: 'k',
        fetch: () async => throw const SocketException('offline'),
      );

      expect(offline.fromCache, isTrue);
      expect(offline.data['value'], 1);
      expect(offline.savedAt, isNotNull);
      expect(offline.networkError, isNotNull);
    });

    test('rethrows when there is nothing cached', () async {
      final cache = cacheIn('empty');

      await expectLater(
        readThroughCache<Map<String, dynamic>>(
          cache: cache,
          key: 'k',
          fetch: () async => throw const SocketException('offline'),
        ),
        throwsA(isA<SocketException>()),
      );
    });

    test('never hides a server rejection', () async {
      final cache = cacheIn('reject');
      await readThroughCache<Map<String, dynamic>>(
        cache: cache,
        key: 'k',
        fetch: () async => {'value': 1},
      );

      await expectLater(
        readThroughCache<Map<String, dynamic>>(
          cache: cache,
          key: 'k',
          shouldFallBack: (_) => false,
          fetch: () async => throw const FormatException('422'),
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('CachedReader', () {
    test('does not cache without a tenant', () async {
      final cache = cacheIn('anon');
      final reader = CachedReader(
        cache: cache,
        scope: () async => CachedReader.anonymous,
        onResult: (_, __) {},
      );

      await reader.read<Map<String, dynamic>>(
        group: 'products',
        key: 'list',
        fetch: () async => {'value': 1},
      );

      expect(await cache.keys(), isEmpty);
    });

    test('namespaces keys per tenant and reports stale reads', () async {
      final cache = cacheIn('tenant');
      final stale = <String, DateTime?>{};
      CachedReader readerFor(String tenant) => CachedReader(
            cache: cache,
            scope: () async => tenant,
            onResult: (group, savedAt) => stale[group] = savedAt,
          );

      await readerFor('b7-u1').read<Map<String, dynamic>>(
        group: 'products',
        key: 'list',
        fetch: () async => {'value': 2},
      );
      expect((await cache.keys()).single, startsWith('b7-u1:'));
      expect(stale['products'], isNull);

      final offline = await readerFor('b7-u1').read<Map<String, dynamic>>(
        group: 'products',
        key: 'list',
        fetch: () async => throw const SocketException('offline'),
      );
      expect(offline['value'], 2);
      expect(stale['products'], isNotNull);
    });
  });

  group('SnapshotScope', () {
    String segment(Object payload) =>
        base64Url.encode(utf8.encode(jsonEncode(payload))).replaceAll('=', '');
    String token(Map<String, dynamic> payload) => 'header.${segment(payload)}.sig';

    test('reads business and user from the JWT payload', () {
      expect(SnapshotScope.fromToken(token({'bid': 7, 'sub': 42})), 'b7-u42');
      expect(SnapshotScope.fromToken(token({'sub': '42'})), 'b0-u42');
    });

    test('treats an unreadable token as anonymous', () {
      expect(SnapshotScope.fromToken('nope'), CachedReader.anonymous);
      expect(
        SnapshotScope.fromToken('header.${segment([1, 2])}.sig'),
        CachedReader.anonymous,
      );
    });
  });
}
