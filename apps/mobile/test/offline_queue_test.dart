import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khata/core/offline/offline_queue.dart';

/// The offline write queue: which failures may be replayed later, what the
/// queued write looks like, and what the form gets back while it is queued.
///
/// `tool/verify_offline_queue.dart` runs the same scenarios as a plain Dart
/// program, because `flutter test` cannot start in this environment; this file
/// is the version that runs on a normal machine.
void main() {
  late List<_Enqueued> enqueued;
  late OfflineQueue queue;

  setUp(() {
    enqueued = [];
    queue = OfflineQueue(
      enqueue: ({
        required String entityType,
        required String operation,
        required String entityId,
        Map<String, dynamic>? payload,
        DateTime? baseUpdatedAt,
      }) async {
        enqueued.add(_Enqueued(entityType, operation, entityId, payload));
      },
    );
  });

  DioException offline([String path = '/customers']) => DioException(
        requestOptions: RequestOptions(path: path),
        type: DioExceptionType.connectionError,
      );

  DioException status(int code) => DioException(
        requestOptions: RequestOptions(path: '/customers'),
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/customers'),
          statusCode: code,
        ),
      );

  group('a write that reaches the server', () {
    test('is not queued and returns the server body', () async {
      final result = await queue.create(
        entityType: 'customer',
        body: {'name': 'Sita'},
        send: () async => {'id': 42, 'name': 'Sita'},
      );

      expect(result.queued, isFalse);
      expect(result.value?['id'], 42);
      expect(result.temporaryId, isNull);
      expect(enqueued, isEmpty);
      expect(queue.queuedCount, 0);
    });
  });

  group('a create with no connection', () {
    test('queues the exact body and returns an optimistic record', () async {
      final body = {'name': 'Sita', 'openingBalance': 5000};
      final result = await queue.create(
        entityType: 'customer',
        body: body,
        send: () async => throw offline(),
      );

      expect(result.queued, isTrue);
      expect(result.temporaryId, lessThan(0));
      expect(result.value?['name'], 'Sita');
      expect(result.value?['id'], result.temporaryId);

      expect(enqueued, hasLength(1));
      expect(enqueued.single.entityType, 'customer');
      expect(enqueued.single.operation, 'create');
      expect(enqueued.single.entityId, '${result.temporaryId}');
      expect(identical(enqueued.single.payload, body), isTrue,
          reason: 'the queued copy must be the body the API would have got');
      expect(queue.queuedCount, 1);
      expect(queue.lastQueuedAt, isNotNull);
    });
  });

  group('an update with no connection', () {
    test('keeps the real id and queues the body', () async {
      final result = await queue.update(
        entityType: 'product',
        entityId: 7,
        body: {'name': 'Rice', 'sellingPrice': 12000},
        send: () async => throw offline('/products/7'),
      );

      expect(result.queued, isTrue);
      expect(result.temporaryId, isNull);
      expect(result.value?['id'], 7);
      expect(enqueued.single.entityId, '7');
      expect(enqueued.single.operation, 'update');
    });
  });

  group('a delete with no connection', () {
    test('queues the id and no payload', () async {
      final result = await queue.remove(
        entityType: 'expense',
        entityId: 3,
        send: () async => throw offline('/expenses/3'),
      );

      expect(result.queued, isTrue);
      expect(enqueued.single.operation, 'delete');
      expect(enqueued.single.entityId, '3');
      expect(enqueued.single.payload, isNull);
    });
  });

  group('failures that must not be queued', () {
    for (final code in [400, 401, 404, 409, 422, 500]) {
      test('$code is rethrown', () async {
        await expectLater(
          queue.create(
            entityType: 'customer',
            body: {'name': 'x'},
            send: () async => throw status(code),
          ),
          throwsA(isA<DioException>()),
        );
        expect(enqueued, isEmpty);
      });
    }

    test('a cancelled request is rethrown', () async {
      await expectLater(
        queue.create(
          entityType: 'customer',
          body: {'name': 'x'},
          send: () async => throw DioException(
            requestOptions: RequestOptions(path: '/customers'),
            type: DioExceptionType.cancel,
          ),
        ),
        throwsA(isA<DioException>()),
      );
      expect(enqueued, isEmpty);
    });
  });

  group('a queue with nothing behind it', () {
    test('rethrows instead of pretending to save', () async {
      final disabled = OfflineQueue.disabled();
      await expectLater(
        disabled.create(
          entityType: 'customer',
          body: {'name': 'x'},
          send: () async => throw offline(),
        ),
        throwsA(isA<DioException>()),
      );
      expect(disabled.isEnabled, isFalse);
      expect(disabled.queuedCount, 0);
    });
  });

  group('temporary ids', () {
    test('are negative, distinct and safe as JSON numbers', () {
      final ids = List.generate(100, (_) => nextTemporaryId());
      expect(ids.every((id) => id < 0), isTrue);
      expect(ids.toSet(), hasLength(ids.length));
      expect(ids.every((id) => id.abs() < 9007199254740992), isTrue);
    });
  });

  group('isWriteInterruption', () {
    test('is true only when the request never got an answer', () {
      expect(isWriteInterruption(offline()), isTrue);
      expect(
        isWriteInterruption(DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.connectionTimeout,
        )),
        isTrue,
      );
      expect(isWriteInterruption(const SocketException('down')), isTrue);
      expect(isWriteInterruption(TimeoutException('slow')), isTrue);
      expect(isWriteInterruption(const HttpException('closed')), isTrue);

      expect(isWriteInterruption(status(422)), isFalse);
      expect(isWriteInterruption(status(500)), isFalse);
      expect(isWriteInterruption(StateError('bug')), isFalse);
    });
  });
}

class _Enqueued {
  _Enqueued(this.entityType, this.operation, this.entityId, this.payload);

  final String entityType;
  final String operation;
  final String entityId;
  final Map<String, dynamic>? payload;
}
