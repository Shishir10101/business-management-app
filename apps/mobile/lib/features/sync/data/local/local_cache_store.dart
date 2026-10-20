import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show MissingPluginException;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// On-device cache for the sync feature.
///
/// NOTE: this is a JSON document store, not a database. The project carries
/// `drift` + `sqlite3_flutter_libs` as dependencies, but Drift requires
/// `build_runner` codegen, which cannot run in this environment — so the cache
/// persists to two JSON files (records + sync queue) instead. It is
/// dependency-free and testable; swap the internals for a Drift database when
/// codegen can run on a dev machine.
///
/// Layout of `khata_sync_cache.json`:
/// ```json
/// {
///   "lastServerCursor": "2026-01-01T00:00:00.000Z",
///   "lastSyncAt": "2026-01-01T00:00:05.000Z",
///   "records": { "product:1": { "id": 1, "name": "Rice" } },
///   "conflicts": [ { "entityType": "customer", "entityId": "7", ... } ]
/// }
/// ```
/// Layout of `khata_sync_queue.json`: a JSON array of queued operation maps.
class LocalCacheStore {
  LocalCacheStore._(this._cacheFile, this._queueFile);

  /// Store with no disk behind it: reads work for the session, writes are
  /// dropped, nothing throws. `_cacheFile`/`_queueFile` being null is the
  /// only marker, so the rest of the class needs no `isWeb` branches.
  LocalCacheStore._session()
      : _cacheFile = null,
        _queueFile = null;

  /// Opens (creating if needed) the store in the app documents directory.
  ///
  /// [documentsDirectory] is injectable so tests can drive both branches: a
  /// real temp folder, or a provider that throws like the browser does.
  ///
  /// A platform with no documents directory — the browser above all, where
  /// neither `path_provider` nor `dart:io` file access exists — degrades to
  /// the in-memory store. Without this the exception escapes through
  /// `SyncRepositoryImpl._cache` into whoever triggered the sync and shows up
  /// as an unhandled page error, which is exactly what the browser walk hit
  /// on the first screen that initialises the offline cache.
  static Future<LocalCacheStore> create({
    Future<Directory> Function()? documentsDirectory,
  }) async {
    try {
      final dir = await (documentsDirectory ?? getApplicationDocumentsDirectory)();
      return LocalCacheStore._(
        File(p.join(dir.path, 'khata_sync_cache.json')),
        File(p.join(dir.path, 'khata_sync_queue.json')),
      );
    } on MissingPluginException {
      return LocalCacheStore._session();
    } on UnsupportedError {
      // dart:io's File is a stub under wasm: any operation throws here.
      return LocalCacheStore._session();
    }
  }

  final File? _cacheFile;
  final File? _queueFile;

  String? _cursor;
  DateTime? _lastSyncAt;
  final Map<String, Map<String, dynamic>> _records = {};
  final List<Map<String, dynamic>> _queue = [];
  final List<Map<String, dynamic>> _conflicts = [];
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final cacheFile = _cacheFile;
    if (cacheFile != null && await cacheFile.exists()) {
      try {
        final decoded =
            jsonDecode(await cacheFile.readAsString()) as Map<String, dynamic>;
        _cursor = decoded['lastServerCursor'] as String?;
        _lastSyncAt = DateTime.tryParse(decoded['lastSyncAt'] as String? ?? '');
        final records = decoded['records'] as Map<String, dynamic>?;
        records?.forEach((key, value) {
          if (value is Map<String, dynamic>) _records[key] = value;
        });
        final conflicts = decoded['conflicts'] as List<dynamic>?;
        if (conflicts != null) {
          _conflicts.addAll(
            conflicts.whereType<Map<String, dynamic>>().toList(),
          );
        }
      } catch (_) {
        // Corrupt cache: start clean rather than crash the app.
        _records.clear();
        _conflicts.clear();
      }
    }
    final queueFile = _queueFile;
    if (queueFile != null && await queueFile.exists()) {
      try {
        final decoded = jsonDecode(await queueFile.readAsString());
        if (decoded is List) {
          _queue.addAll(decoded.whereType<Map<String, dynamic>>().toList());
        }
      } catch (_) {
        _queue.clear();
      }
    }
    _loaded = true;
  }

  Future<void> _saveCache() async {
    final file = _cacheFile;
    if (file == null) return; // Session-only store: nothing to persist to.
    await file.writeAsString(jsonEncode({
      'lastServerCursor': _cursor,
      'lastSyncAt': _lastSyncAt?.toIso8601String(),
      'records': _records,
      'conflicts': _conflicts,
    }));
  }

  Future<void> _saveQueue() async {
    final file = _queueFile;
    if (file == null) return; // Session-only store: nothing to persist to.
    await file.writeAsString(jsonEncode(_queue));
  }

  /// Writes (or overwrites) a record pulled from the server.
  Future<void> upsert(String entityType, Map<String, dynamic> record) async {
    await _ensureLoaded();
    final id = (record['id'] ?? '').toString();
    if (id.isEmpty) return;
    _records['$entityType:$id'] = Map<String, dynamic>.from(record);
    await _saveCache();
  }

  /// Swaps a locally invented id for the one the server assigned.
  ///
  /// A record created offline is queued under a negative temporary id. Once the
  /// create reaches the server, that id is meaningless: the cached row and any
  /// still-queued update/delete for it must point at the real id, or every
  /// later operation is rejected with "record does not exist".
  Future<void> remapEntityId(
    String entityType,
    String fromId,
    String toId,
  ) async {
    await _ensureLoaded();
    if (fromId.isEmpty || toId.isEmpty || fromId == toId) return;

    final cached = _records.remove('$entityType:$fromId');
    if (cached != null) {
      _records['$entityType:$toId'] = {
        ...cached,
        // Server ids arrive as JSON numbers; keep the row's shape intact.
        'id': int.tryParse(toId) ?? cached['id'] ?? toId,
      };
    }

    var queueChanged = false;
    for (var i = 0; i < _queue.length; i++) {
      final op = _queue[i];
      if (op['entityType'] == entityType &&
          op['entityId']?.toString() == fromId) {
        _queue[i] = {...op, 'entityId': toId};
        queueChanged = true;
      }
    }

    await _saveCache();
    if (queueChanged) await _saveQueue();
  }

  /// Records a server-side deletion as a tombstone so cached views can hide it.
  Future<void> markDeleted(String entityType, String id) async {
    await _ensureLoaded();
    _records['$entityType:$id'] = {'id': id, '_deleted': true};
    await _saveCache();
  }

  /// All cached records of one entity type (tombstones included).
  Future<List<Map<String, dynamic>>> getRecords(String entityType) async {
    await _ensureLoaded();
    return _records.entries
        .where((entry) => entry.key.startsWith('$entityType:'))
        .map((entry) => entry.value)
        .toList();
  }

  Future<String?> get lastServerCursor async {
    await _ensureLoaded();
    return _cursor;
  }

  Future<void> setLastServerCursor(String? cursor) async {
    await _ensureLoaded();
    _cursor = cursor;
    await _saveCache();
  }

  Future<DateTime?> get lastSyncAt async {
    await _ensureLoaded();
    return _lastSyncAt;
  }

  Future<void> setLastSyncAt(DateTime? at) async {
    await _ensureLoaded();
    _lastSyncAt = at;
    await _saveCache();
  }

  /// Queued operations, oldest first.
  Future<List<Map<String, dynamic>>> get queuedOperations async {
    await _ensureLoaded();
    return List<Map<String, dynamic>>.unmodifiable(_queue);
  }

  Future<void> enqueueOperation(Map<String, dynamic> operation) async {
    await _ensureLoaded();
    _queue.removeWhere(
      (op) => op['operationId'] == operation['operationId'],
    );
    _queue.add(operation);
    await _saveQueue();
  }

  Future<void> removeOperation(String operationId) async {
    await _ensureLoaded();
    _queue.removeWhere((op) => op['operationId'] == operationId);
    await _saveQueue();
  }

  /// Bumps the retry counter / last error for a queued operation that failed
  /// to reach the server (network error, not a server rejection).
  Future<void> recordAttemptFailure(String operationId, String error) async {
    await _ensureLoaded();
    for (var i = 0; i < _queue.length; i++) {
      if (_queue[i]['operationId'] == operationId) {
        _queue[i] = {
          ..._queue[i],
          'attempts': ((_queue[i]['attempts'] as num?)?.toInt() ?? 0) + 1,
          'lastError': error,
        };
        break;
      }
    }
    await _saveQueue();
  }

  Future<void> setConflicts(List<Map<String, dynamic>> conflicts) async {
    await _ensureLoaded();
    _conflicts
      ..clear()
      ..addAll(conflicts);
    await _saveCache();
  }

  Future<List<Map<String, dynamic>>> get conflicts async {
    await _ensureLoaded();
    return List<Map<String, dynamic>>.unmodifiable(_conflicts);
  }

  /// Wipes the cache and the queue (sign-out / reset).
  Future<void> clear() async {
    await _ensureLoaded();
    _records.clear();
    _queue.clear();
    _conflicts.clear();
    _cursor = null;
    _lastSyncAt = null;
    await _saveCache();
    await _saveQueue();
  }
}
