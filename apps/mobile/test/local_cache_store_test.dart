import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khata/features/sync/data/local/local_cache_store.dart';

/// The sync feature's on-device record + queue store.
///
/// Two things matter: it really persists across instances when there is a
/// documents directory, and it degrades to a session-only store instead of
/// throwing when there is not. The second is the browser-walk defect — an
/// unguarded `getApplicationDocumentsDirectory()` escaped through
/// `SyncRepositoryImpl._cache` and surfaced as an unhandled page error.
void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('khata_cache_test_'));
  tearDown(() {
    try {
      root.deleteSync(recursive: true);
    } catch (_) {}
  });

  Directory storeIn(String name) {
    final dir = Directory('${root.path}/$name')..createSync(recursive: true);
    return dir;
  }

  test('persists records, the queue and the cursor across instances', () async {
    final store = await LocalCacheStore.create(
      documentsDirectory: () async => storeIn('shared'),
    );
    await store.upsert('product', {'id': 1, 'name': 'Rice'});
    await store.enqueueOperation({
      'operationId': 'op-1',
      'entityType': 'product',
    });
    await store.setLastServerCursor('2026-01-01T00:00:00.000Z');

    final reopened = await LocalCacheStore.create(
      documentsDirectory: () async => storeIn('shared'),
    );

    final records = await reopened.getRecords('product');
    expect(records, hasLength(1));
    expect(records.first['name'], 'Rice');
    expect(await reopened.queuedOperations, hasLength(1));
    expect(await reopened.lastServerCursor, '2026-01-01T00:00:00.000Z');
  });

  test('a corrupt cache file is dropped rather than thrown', () async {
    final dir = storeIn('corrupt');
    File('${dir.path}/khata_sync_cache.json').writeAsStringSync('{not json');

    final store = await LocalCacheStore.create(
      documentsDirectory: () async => dir,
    );

    expect(await store.getRecords('product'), isEmpty);
  });

  test('clear() empties both the records and the queue', () async {
    final dir = storeIn('cleared');
    final store = await LocalCacheStore.create(
      documentsDirectory: () async => dir,
    );
    await store.upsert('customer', {'id': 7, 'name': 'Ram'});
    await store.enqueueOperation({'operationId': 'op-2'});

    await store.clear();

    expect(await store.getRecords('customer'), isEmpty);
    expect(await store.queuedOperations, isEmpty);
  });

  test('a missing documents directory degrades to a session store', () async {
    // Exactly what the browser does: no implementation for the method channel.
    final store = await LocalCacheStore.create(
      documentsDirectory: () async =>
          throw MissingPluginException('getApplicationDocumentsDirectory'),
    );

    // Reads still work for this session...
    await store.upsert('customer', {'id': 7, 'name': 'Ram'});
    expect(await store.getRecords('customer'), hasLength(1));
    expect((await store.getRecords('customer')).first['name'], 'Ram');

    // ...writes are dropped instead of throwing...
    await store.setLastServerCursor('2026-01-01T00:00:00.000Z');
    expect(await store.lastServerCursor, '2026-01-01T00:00:00.000Z');
    await store.enqueueOperation({'operationId': 'op-3'});
    expect(await store.queuedOperations, hasLength(1));

    // ...and nothing was persisted anywhere.
    expect(
      root
          .listSync(recursive: true)
          .where((entry) => entry.path.contains('khata_sync')),
      isEmpty,
    );
  });

  test('an unsupported dart:io (wasm) degrades to a session store', () async {
    final store = await LocalCacheStore.create(
      documentsDirectory: () async =>
          throw UnsupportedError('dart:io file access is not available'),
    );

    await store.upsert('product', {'id': 1, 'name': 'Rice'});
    expect(await store.getRecords('product'), hasLength(1));
    await store.setLastServerCursor('c');
    expect(await store.lastServerCursor, 'c');
  });

  test('a session store never resurrects rows from a previous session', () async {
    final first = await LocalCacheStore.create(
      documentsDirectory: () async =>
          throw MissingPluginException('getApplicationDocumentsDirectory'),
    );
    await first.upsert('product', {'id': 1, 'name': 'Rice'});

    final second = await LocalCacheStore.create(
      documentsDirectory: () async =>
          throw MissingPluginException('getApplicationDocumentsDirectory'),
    );

    expect(await second.getRecords('product'), isEmpty);
  });
}
