// Verifies the offline snapshot cache without the Flutter test runner.
//
// `flutter test` cannot run in this environment (flutter_tester's websocket
// upgrade fails), and these classes are deliberately plain Dart — no widgets,
// no plugins — so they can be exercised directly:
//
//     dart run tool/verify_offline_cache.dart
//
// Exits non-zero if anything fails, so it can gate a change like the python
// checkers do. test/offline_cache_test.dart covers the same ground through
// flutter_test for CI on a machine where that runner works.

import 'dart:convert';
import 'dart:io';

import 'package:khata/core/offline/cached_read.dart';
import 'package:khata/core/offline/cached_reader.dart';
import 'package:khata/core/offline/snapshot_cache.dart';

int failures = 0;

void check(String name, bool condition, [String? detail]) {
  if (condition) {
    stdout.writeln('  ok   $name');
  } else {
    failures++;
    stdout.writeln('  FAIL $name${detail == null ? '' : ' — $detail'}');
  }
}

Future<void> main() async {
  final root = Directory.systemTemp.createTempSync('khata_offline_');
  try {
    await runChecks(root);
  } finally {
    try {
      root.deleteSync(recursive: true);
    } catch (_) {}
  }

  if (failures == 0) {
    stdout.writeln('\nall offline-cache checks passed');
  } else {
    stderr.writeln('\n$failures offline-cache check(s) FAILED');
    exit(1);
  }
}

Future<void> runChecks(Directory root) async {
  await roundTrip(root);
  await persistence(root);
  await eviction(root);
  await corruption(root);
  await fallback(root);
  await readerScoping(root);
  await tokenScope();
}

Future<void> roundTrip(Directory root) async {
  stdout.writeln('snapshot cache');
  final cache = SnapshotCache(directory: () async => root);

  check('miss before write', await cache.read('k') == null);

  await cache.write('k', {
    'data': [
      {'id': 1, 'name': 'Rice'},
    ],
  });

  final snapshot = await cache.read('k');
  check('hit after write', snapshot != null);
  check(
    'payload survives the round trip',
    snapshot != null &&
        (snapshot.json as Map)['data'] is List &&
        ((snapshot.json as Map)['data'] as List).length == 1,
  );
  check('savedAt is set', snapshot != null &&
      DateTime.now().difference(snapshot.savedAt).inMinutes.abs() < 5);

  await cache.remove('k');
  check('remove drops the entry', await cache.read('k') == null);
}

Future<void> persistence(Directory root) async {
  final first = SnapshotCache(directory: () async => root);
  await first.write('list', {'data': []});
  check('writes reach the disk', first.isPersistent);

  // A second instance reads what the first one wrote — the point of the cache.
  final second = SnapshotCache(directory: () async => root);
  check('a new instance reads the file', await second.read('list') != null);

  await second.clear();
  check('clear empties the cache', (await second.keys()).isEmpty);
  final third = SnapshotCache(directory: () async => root);
  check('clear deletes the file', (await third.keys()).isEmpty);
}

Future<void> eviction(Directory root) async {
  final dir = Directory('${root.path}/evict')..createSync(recursive: true);
  final cache = SnapshotCache(
    directory: () async => dir,
    maxEntries: 3,
    clock: () => DateTime(2026, 1, 1).add(_tick()),
  );

  for (var i = 0; i < 5; i++) {
    await cache.write('k$i', {'i': i});
  }

  final keys = await cache.keys();
  check('entry count is capped', cache.length == 3, 'kept ${cache.length}');
  check('the newest survives', keys.contains('k4'));
  check('the oldest is dropped', !keys.contains('k0'));

  final bytesCache = SnapshotCache(
    directory: () async => Directory('${root.path}/bytes')
      ..createSync(recursive: true),
    maxEntries: 50,
    maxBytes: 400,
  );
  for (var i = 0; i < 20; i++) {
    await bytesCache.write('big$i', {'padding': 'x' * 40, 'i': i});
  }
  check(
    'byte budget is respected',
    bytesCache.sizeInBytes <= 400,
    'size ${bytesCache.sizeInBytes}',
  );
  check('at least one entry survives the budget', bytesCache.length >= 1);
}

Duration _tick() => Duration(seconds: _counter += 1);
int _counter = 0;

Future<void> corruption(Directory root) async {
  final dir = Directory('${root.path}/corrupt')..createSync(recursive: true);
  File('${dir.path}/khata_snapshots.json').writeAsStringSync('{not json');

  final cache = SnapshotCache(directory: () async => dir);
  check('a corrupt file is a miss, not a crash', await cache.read('k') == null);

  await cache.write('k', {'ok': true});
  check('the cache recovers after corruption', await cache.read('k') != null);

  final noDir = SnapshotCache(
    directory: () async => throw const FileSystemException('no directory'),
  );
  check('a missing directory degrades quietly', await noDir.read('k') == null);
  await noDir.write('k', {'ok': true});
  check('memory-only cache still serves', await noDir.read('k') != null);
  check('and reports itself as non-persistent', !noDir.isPersistent);
}

Future<void> fallback(Directory root) async {
  stdout.writeln('cache-first read');
  final dir = Directory('${root.path}/read')..createSync(recursive: true);
  final cache = SnapshotCache(directory: () async => dir);

  final fresh = await readThroughCache<Map<String, dynamic>>(
    cache: cache,
    key: 'k',
    fetch: () async => {'value': 1},
  );
  check('a successful read is not marked as cached', !fresh.fromCache);

  final offline = await readThroughCache<Map<String, dynamic>>(
    cache: cache,
    key: 'k',
    fetch: () async => throw const SocketException('offline'),
  );
  check('a network failure falls back', offline.fromCache);
  check('the cached payload is returned', offline.data['value'] == 1);
  check('the failure is reported', offline.networkError != null);
  check('savedAt comes from the snapshot', offline.savedAt != null);

  var threw = false;
  try {
    await readThroughCache<Map<String, dynamic>>(
      cache: cache,
      key: 'never-written',
      fetch: () async => throw const SocketException('offline'),
    );
  } catch (_) {
    threw = true;
  }
  check('no cache + offline rethrows', threw);

  var rejected = false;
  try {
    await readThroughCache<Map<String, dynamic>>(
      cache: cache,
      key: 'k',
      shouldFallBack: (_) => false,
      fetch: () async => throw const FormatException('422'),
    );
  } catch (_) {
    rejected = true;
  }
  check('a server rejection is not hidden by stale data', rejected);
}

Future<void> readerScoping(Directory root) async {
  final dir = Directory('${root.path}/scope')..createSync(recursive: true);
  final cache = SnapshotCache(directory: () async => dir);
  final results = <String, DateTime?>{};

  CachedReader readerFor(String tenant) => CachedReader(
        cache: cache,
        scope: () async => tenant,
        onResult: (group, savedAt) => results[group] = savedAt,
      );

  var calls = 0;
  await readerFor(CachedReader.anonymous).read<Map<String, dynamic>>(
    group: 'products',
    key: 'list',
    fetch: () async {
      calls++;
      return {'value': 1};
    },
  );
  check('an unknown tenant reads straight through', calls == 1);
  check('and caches nothing', (await cache.keys()).isEmpty);

  await readerFor('b7-u1').read<Map<String, dynamic>>(
    group: 'products',
    key: 'list',
    fetch: () async => {'value': 2},
  );
  final keys = await cache.keys();
  check('the key is namespaced by tenant', keys.single.startsWith('b7-u1:'));
  check('a fresh read clears the stale marker', results['products'] == null);

  // Another tenant must not see business 7's cached list.
  var otherFetches = 0;
  await readerFor('b8-u1').read<Map<String, dynamic>>(
    group: 'products',
    key: 'list',
    fetch: () async {
      otherFetches++;
      return {'value': 3};
    },
  );
  check('another tenant gets its own read', otherFetches == 1);

  // ... and the first tenant, offline, still gets its own copy.
  final offline = await readerFor('b7-u1').read<Map<String, dynamic>>(
    group: 'products',
    key: 'list',
    fetch: () async => throw const SocketException('offline'),
  );
  check('the tenant gets its saved copy back', offline['value'] == 2);
  check('the stale marker is set', results['products'] != null);
}

Future<void> tokenScope() async {
  stdout.writeln('token scope');

  String segment(Object payload) =>
      base64Url.encode(utf8.encode(jsonEncode(payload))).replaceAll('=', '');
  String token(Map<String, dynamic> payload) => 'header.${segment(payload)}.sig';

  check(
    'business + user come from the JWT',
    SnapshotScope.fromToken(token({'bid': 7, 'sub': 42})) == 'b7-u42',
    SnapshotScope.fromToken(token({'bid': 7, 'sub': 42})),
  );
  check(
    'a token without a business still scopes by user',
    SnapshotScope.fromToken(token({'sub': '42'})) == 'b0-u42',
  );
  check('garbage is anonymous',
      SnapshotScope.fromToken('nope') == CachedReader.anonymous);
  check(
    'a non-map payload is anonymous',
    SnapshotScope.fromToken('header.${segment([1, 2])}.sig') ==
        CachedReader.anonymous,
  );

  var reads = 0;
  final scope = SnapshotScope(() async {
    reads++;
    return token({'bid': 3, 'sub': 9});
  });
  check('resolves to the session scope', await scope.resolve() == 'b3-u9');
  check('and stays stable on the next resolve', await scope.resolve() == 'b3-u9');
  check('the token is read per resolve', reads == 2);
}
