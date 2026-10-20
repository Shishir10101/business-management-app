import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

/// Signature of the function that stores one local write for later delivery.
///
/// The sync feature implements this over `SyncRepository.enqueue`; keeping it a
/// plain typedef means this file stays free of Flutter *and* of the sync
/// feature, so it can be exercised by `dart run tool/verify_offline_queue.dart`.
typedef EnqueueWrite = Future<void> Function({
  required String entityType,
  required String operation,
  required String entityId,
  Map<String, dynamic>? payload,
  DateTime? baseUpdatedAt,
});

/// Outcome of a write that may have been queued instead of sent.
///
/// [value] is what the repository would have received from the API: the real
/// response body, or — when [queued] — a locally synthesized body so the form
/// can still close without a type error. [temporaryId] is that synthesized
/// record's id (always negative), which the push cycle later swaps for the
/// server's real id.
class OfflineWriteResult<T> {
  const OfflineWriteResult({
    this.value,
    this.queued = false,
    this.temporaryId,
  });

  final T? value;
  final bool queued;
  final int? temporaryId;
}

/// Runs a write against the API, and falls back to the sync queue when the
/// network is not there.
///
/// This is the write-side twin of `readThroughCache`: the *same* JSON body the
/// API would have received is what gets queued, so the offline path cannot
/// drift from the online one. A server refusal (4xx) or a server fault that
/// may already have committed (5xx) is rethrown — see [isWriteInterruption].
class OfflineQueue {
  OfflineQueue({required EnqueueWrite enqueue})
      : _enqueue = enqueue,
        _enabled = true;

  /// A queue with nothing behind it: every write goes straight to the network
  /// and a failure propagates. Used by tests and by any caller that does not
  /// wire the sync feature.
  OfflineQueue.disabled()
      : _enqueue = null,
        _enabled = false;

  final EnqueueWrite? _enqueue;
  final bool _enabled;

  int _queuedCount = 0;
  DateTime? _lastQueuedAt;

  /// How many writes this queue has taken since the app started. Callers
  /// compare it before and after a save to know whether to say "saved offline".
  int get queuedCount => _queuedCount;

  /// When the last write was queued (null until the first one).
  DateTime? get lastQueuedAt => _lastQueuedAt;

  /// True when this queue can actually take a write.
  bool get isEnabled => _enabled;

  /// POST-like create. Returns the API body, or an optimistic body carrying a
  /// temporary negative [OfflineWriteResult.temporaryId].
  Future<OfflineWriteResult<Map<String, dynamic>>> create({
    required String entityType,
    required Map<String, dynamic> body,
    required Future<Map<String, dynamic>> Function() send,
  }) async {
    try {
      return OfflineWriteResult(value: await send());
    } catch (error) {
      if (!_canQueue(error)) rethrow;

      final temporaryId = nextTemporaryId();
      await _enqueue!(
        entityType: entityType,
        operation: 'create',
        entityId: temporaryId.toString(),
        payload: body,
      );
      _recordQueued();
      return OfflineWriteResult(
        value: {...body, 'id': temporaryId},
        queued: true,
        temporaryId: temporaryId,
      );
    }
  }

  /// PUT-like update of an existing record.
  Future<OfflineWriteResult<Map<String, dynamic>>> update({
    required String entityType,
    required int entityId,
    required Map<String, dynamic> body,
    required Future<Map<String, dynamic>> Function() send,
  }) async {
    try {
      return OfflineWriteResult(value: await send());
    } catch (error) {
      if (!_canQueue(error)) rethrow;

      await _enqueue!(
        entityType: entityType,
        operation: 'update',
        entityId: entityId.toString(),
        payload: body,
      );
      _recordQueued();
      return OfflineWriteResult(
        value: {...body, 'id': entityId},
        queued: true,
      );
    }
  }

  /// DELETE of an existing record.
  Future<OfflineWriteResult<void>> remove({
    required String entityType,
    required int entityId,
    required Future<void> Function() send,
  }) async {
    try {
      await send();
      return const OfflineWriteResult<void>();
    } catch (error) {
      if (!_canQueue(error)) rethrow;

      await _enqueue!(
        entityType: entityType,
        operation: 'delete',
        entityId: entityId.toString(),
      );
      _recordQueued();
      return const OfflineWriteResult<void>(queued: true);
    }
  }

  bool _canQueue(Object error) => _enabled && isWriteInterruption(error);

  void _recordQueued() {
    _queuedCount++;
    _lastQueuedAt = DateTime.now();
  }
}

/// True when a failed write can be safely replayed later.
///
/// Only a request that never got an answer qualifies. A 4xx is a refusal, and a
/// 5xx may have committed the change before it failed — queueing either would
/// duplicate work the server already did (a second sale, a second payment).
/// The user sees the error and can decide to retry.
bool isWriteInterruption(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
        return false;
      default:
        return error.response == null;
    }
  }
  return error is SocketException ||
      error is TimeoutException ||
      error is HttpException;
}

int _temporaryIdSeed = 0;

/// A locally invented id for a record that does not exist on the server yet.
///
/// Negative, so it can never collide with a real (always positive) database id,
/// and derived from the clock so two devices cannot produce the same one. The
/// push cycle replaces it with the server id (see `LocalCacheStore.remapEntityId`).
int nextTemporaryId() =>
    -(DateTime.now().microsecondsSinceEpoch + _temporaryIdSeed++);
