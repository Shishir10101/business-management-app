import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// A JSON payload a screen last rendered, and when it was saved.
class Snapshot {
  const Snapshot({required this.json, required this.savedAt});

  /// Whatever the API returned for that read — a list envelope or a list.
  final Object? json;

  final DateTime savedAt;
}

/// A small, persistent cache of "the last good answer" per screen query.
///
/// This is deliberately NOT the sync store (`features/sync/data/local`). That
/// one mirrors server rows for the push/pull protocol and is only filled by a
/// sync; this one stores the *response body* a screen actually rendered, so a
/// list can be shown again when the request fails. Keeping them apart means a
/// screen never has to understand the sync payload shape, and a failed read
/// never touches sync state.
///
/// Everything here degrades to "no cache" instead of throwing: a missing
/// documents directory, a corrupt file or a full disk must never take a screen
/// down. [isPersistent] reports whether writes reach the disk.
class SnapshotCache {
  SnapshotCache({
    required Future<Directory> Function() directory,
    this.maxEntries = 24,
    this.maxBytes = 3 * 1024 * 1024,
    this.fileName = 'khata_snapshots.json',
    DateTime Function()? clock,
  })  : _directory = directory,
        _clock = clock ?? DateTime.now;

  static const int version = 1;

  /// Snapshots kept before the least-recently-used one is dropped.
  final int maxEntries;

  /// On-disk budget. Older snapshots are dropped to stay under it.
  final int maxBytes;

  final String fileName;

  final Future<Directory> Function() _directory;
  final DateTime Function() _clock;

  final Map<String, Snapshot> _entries = {};
  final Map<String, DateTime> _lastUsed = {};

  File? _file;
  bool _loaded = false;
  bool _persistent = true;
  int _bytes = 0;

  /// False when the cache could only be held in memory.
  bool get isPersistent => _persistent;

  /// Number of cached snapshots.
  int get length => _entries.length;

  /// Size of the serialized cache, in characters.
  int get sizeInBytes => _bytes;

  Future<Snapshot?> read(String key) async {
    await _ensureLoaded();
    final snapshot = _entries[key];
    if (snapshot == null) return null;
    _lastUsed[key] = _clock();
    return snapshot;
  }

  Future<void> write(String key, Object? json) async {
    if (json == null) return;
    await _ensureLoaded();

    final now = _clock();
    _entries[key] = Snapshot(json: json, savedAt: now);
    _lastUsed[key] = now;
    _evictByCount();
    await _save();
  }

  Future<void> remove(String key) async {
    await _ensureLoaded();
    if (_entries.remove(key) == null) return;
    _lastUsed.remove(key);
    await _save();
  }

  Future<void> clear() async {
    await _ensureLoaded();
    _entries.clear();
    _lastUsed.clear();
    _bytes = 0;
    try {
      final file = _file;
      if (file != null && await file.exists()) await file.delete();
    } catch (_) {
      // Nothing to do: the in-memory cache is already empty.
    }
  }

  /// Cached keys, most recently used first. Diagnostics only.
  Future<List<String>> keys() async {
    await _ensureLoaded();
    final sorted = _entries.keys.toList()
      ..sort((a, b) {
        final left = _lastUsed[a] ?? DateTime.fromMillisecondsSinceEpoch(0);
        final right = _lastUsed[b] ?? DateTime.fromMillisecondsSinceEpoch(0);
        return right.compareTo(left);
      });
    return sorted;
  }

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;

    try {
      final dir = await _directory();
      _file = File(p.join(dir.path, fileName));
    } catch (_) {
      // No documents directory (a test, a platform without the plugin): keep
      // the cache in memory for this session and never try to write.
      _persistent = false;
      return;
    }

    try {
      final file = _file!;
      if (!await file.exists()) return;
      final raw = await file.readAsString();
      _bytes = utf8.encode(raw).length;
      if (raw.trim().isEmpty) return;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final entries = decoded['entries'];
      if (entries is! Map) return;

      entries.forEach((key, value) {
        if (value is! Map) return;
        final savedAt = DateTime.tryParse(value['savedAt'] as String? ?? '');
        if (savedAt == null) return;
        _entries['$key'] = Snapshot(json: value['json'], savedAt: savedAt);
        _lastUsed['$key'] = savedAt;
      });
    } catch (_) {
      // Corrupt cache: start clean rather than crash. The file is rewritten on
      // the next successful write.
      _entries.clear();
      _lastUsed.clear();
      _bytes = 0;
    }
  }

  void _evictByCount() {
    while (_entries.length > maxEntries) {
      final victim = _leastRecentlyUsed();
      if (victim == null) return;
      _entries.remove(victim);
      _lastUsed.remove(victim);
    }
  }

  String? _leastRecentlyUsed() {
    String? victim;
    DateTime? oldest;
    for (final key in _entries.keys) {
      final used = _lastUsed[key] ?? DateTime.fromMillisecondsSinceEpoch(0);
      if (oldest == null || used.isBefore(oldest)) {
        oldest = used;
        victim = key;
      }
    }
    return victim;
  }

  Future<void> _save() async {
    final file = _file;
    if (file == null || !_persistent) return;

    var payload = _encode();
    // Measured in UTF-8 bytes, not characters: Devanagari text is up to three
    // bytes per character, so a character budget would let the file grow well
    // past the advertised size on a Nepali device.
    var size = utf8.encode(payload).length;

    // Stay inside the byte budget by dropping the oldest snapshots. One entry
    // always survives, so a single huge response cannot empty the cache.
    var guard = 0;
    while (size > maxBytes && _entries.length > 1 && guard++ < 100) {
      final victim = _leastRecentlyUsed();
      if (victim == null) break;
      _entries.remove(victim);
      _lastUsed.remove(victim);
      payload = _encode();
      size = utf8.encode(payload).length;
    }
    _bytes = size;

    try {
      await file.parent.create(recursive: true);
      await file.writeAsString(payload);
    } catch (_) {
      // Disk full or read-only: keep serving from memory.
      _persistent = false;
    }
  }

  String _encode() => jsonEncode({
        'version': version,
        'entries': {
          for (final entry in _entries.entries)
            entry.key: {
              'savedAt': entry.value.savedAt.toIso8601String(),
              'json': entry.value.json,
            },
        },
      });
}
