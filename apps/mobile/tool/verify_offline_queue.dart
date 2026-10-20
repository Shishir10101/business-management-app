// Verifies the offline write queue without the Flutter test runner.
//
// `flutter test` cannot run in this environment (flutter_tester's websocket
// upgrade fails) and `OfflineQueue` is deliberately plain Dart, so it can be
// exercised directly:
//
//     dart run tool/verify_offline_queue.dart
//
// Exits non-zero if anything fails, so it can gate a change like the python
// checkers do. test/offline_queue_test.dart covers the same ground through
// flutter_test for CI on a machine where that runner works.

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:khata/core/offline/offline_queue.dart';

int failures = 0;

void check(String name, bool condition, [String? detail]) {
  if (condition) {
    stdout.writeln('  ok   $name');
  } else {
    failures++;
    stdout.writeln('  FAIL $name${detail == null ? '' : ' — $detail'}');
  }
}

/// One call the queue made to the sync layer.
class Enqueued {
  Enqueued(this.entityType, this.operation, this.entityId, this.payload);

  final String entityType;
  final String operation;
  final String entityId;
  final Map<String, dynamic>? payload;
}

Future<void> main() async {
  await successPath();
  await createQueued();
  await updateQueued();
  await deleteQueued();
  await refusals();
  await disabledQueue();
  await temporaryIds();
  await classification();

  if (failures == 0) {
    stdout.writeln('\nall offline-queue checks passed');
  } else {
    stderr.writeln('\n$failures offline-queue check(s) FAILED');
    exit(1);
  }
}

/// A queue plus the list of writes it stored.
class Harness {
  Harness() {
    queue = OfflineQueue(
      enqueue: ({
        required String entityType,
        required String operation,
        required String entityId,
        Map<String, dynamic>? payload,
        DateTime? baseUpdatedAt,
      }) async {
        enqueued.add(Enqueued(entityType, operation, entityId, payload));
      },
    );
  }

  late final OfflineQueue queue;
  final List<Enqueued> enqueued = [];
}

DioException _offline([String path = '/customers']) => DioException(
      requestOptions: RequestOptions(path: path),
      type: DioExceptionType.connectionError,
      message: 'connection refused',
    );

DioException _status(int code, [String path = '/customers']) => DioException(
      requestOptions: RequestOptions(path: path),
      type: DioExceptionType.badResponse,
      response: Response<dynamic>(
        requestOptions: RequestOptions(path: path),
        statusCode: code,
      ),
    );

Future<void> successPath() async {
  stdout.writeln('a write that reaches the server');
  final harness = Harness();

  final result = await harness.queue.create(
    entityType: 'customer',
    body: {'name': 'Sita'},
    send: () async => {'id': 42, 'name': 'Sita'},
  );

  check('not queued', !result.queued);
  check('returns the server body', result.value?['id'] == 42);
  check('no temporary id', result.temporaryId == null);
  check('nothing enqueued', harness.enqueued.isEmpty);
  check('counter untouched', harness.queue.queuedCount == 0);
  check('lastQueuedAt still null', harness.queue.lastQueuedAt == null);
}

Future<void> createQueued() async {
  stdout.writeln('a create with no connection');
  final harness = Harness();
  final body = {'name': 'Sita', 'openingBalance': 5000};

  final result = await harness.queue.create(
    entityType: 'customer',
    body: body,
    send: () async => throw _offline(),
  );

  check('queued', result.queued);
  check('one write stored', harness.enqueued.length == 1);
  check('entity type is customer',
      harness.enqueued.single.entityType == 'customer');
  check('operation is create', harness.enqueued.single.operation == 'create');
  check(
    'the queued payload is the exact body the API would have received',
    identical(harness.enqueued.single.payload, body),
  );
  check('queued entity id is the temporary id',
      harness.enqueued.single.entityId == '${result.temporaryId}');
  check('temporary id is negative', (result.temporaryId ?? 0) < 0);
  check(
    'optimistic body keeps the fields and carries the temporary id',
    result.value?['name'] == 'Sita' &&
        result.value?['openingBalance'] == 5000 &&
        result.value?['id'] == result.temporaryId,
  );
  check('counter incremented', harness.queue.queuedCount == 1);
  check('lastQueuedAt set', harness.queue.lastQueuedAt != null);
}

Future<void> updateQueued() async {
  stdout.writeln('an update with no connection');
  final harness = Harness();

  final result = await harness.queue.update(
    entityType: 'product',
    entityId: 7,
    body: {'name': 'Rice', 'sellingPrice': 12000},
    send: () async => throw _offline('/products/7'),
  );

  check('queued', result.queued);
  check('entity id preserved', harness.enqueued.single.entityId == '7');
  check('operation is update', harness.enqueued.single.operation == 'update');
  check('no temporary id for an update', result.temporaryId == null);
  check(
    'optimistic body keeps the real id',
    result.value?['id'] == 7 && result.value?['sellingPrice'] == 12000,
  );
}

Future<void> deleteQueued() async {
  stdout.writeln('a delete with no connection');
  final harness = Harness();

  final result = await harness.queue.remove(
    entityType: 'expense',
    entityId: 3,
    send: () async => throw _offline('/expenses/3'),
  );

  check('queued', result.queued);
  check('operation is delete', harness.enqueued.single.operation == 'delete');
  check('delete carries no payload', harness.enqueued.single.payload == null);
  check('entity id preserved', harness.enqueued.single.entityId == '3');
}

Future<void> refusals() async {
  stdout.writeln('failures that must NOT be queued');

  for (final code in [400, 401, 404, 409, 422]) {
    final harness = Harness();
    var threw = false;
    try {
      await harness.queue.create(
        entityType: 'customer',
        body: {'name': 'x'},
        send: () async => throw _status(code),
      );
    } catch (_) {
      threw = true;
    }
    check('$code rethrows instead of queueing',
        threw && harness.enqueued.isEmpty);
  }

  // A 5xx may have committed the write before failing: replaying it could
  // duplicate a sale or a payment, so it surfaces as an error instead.
  final harness = Harness();
  var threw = false;
  try {
    await harness.queue.create(
      entityType: 'sale',
      body: {'saleType': 'Cash'},
      send: () async => throw _status(500, '/sales'),
    );
  } catch (_) {
    threw = true;
  }
  check('500 rethrows instead of queueing', threw && harness.enqueued.isEmpty);

  final cancelled = Harness();
  var cancelThrew = false;
  try {
    await cancelled.queue.create(
      entityType: 'customer',
      body: {'name': 'x'},
      send: () async => throw DioException(
        requestOptions: RequestOptions(path: '/customers'),
        type: DioExceptionType.cancel,
      ),
    );
  } catch (_) {
    cancelThrew = true;
  }
  check('a cancelled request is not queued',
      cancelThrew && cancelled.enqueued.isEmpty);
}

Future<void> disabledQueue() async {
  stdout.writeln('a queue with no sync feature behind it');
  final queue = OfflineQueue.disabled();
  var threw = false;
  try {
    await queue.create(
      entityType: 'customer',
      body: {'name': 'x'},
      send: () async => throw _offline(),
    );
  } catch (_) {
    threw = true;
  }
  check('offline write rethrows', threw);
  check('nothing counted', queue.queuedCount == 0);
  check('not enabled', !queue.isEnabled);

  final ok = await queue.create(
    entityType: 'customer',
    body: {'name': 'x'},
    send: () async => {'id': 1, 'name': 'x'},
  );
  check('online write still works', !ok.queued && ok.value?['id'] == 1);
}

Future<void> temporaryIds() async {
  stdout.writeln('temporary ids');
  final ids = List.generate(50, (_) => nextTemporaryId());
  check('all negative', ids.every((id) => id < 0));
  check('all distinct', ids.toSet().length == ids.length);
  check(
    'fit in a JSON number (|id| < 2^53)',
    ids.every((id) => id.abs() < 9007199254740992),
  );
}

Future<void> classification() async {
  stdout.writeln('what counts as "the network is not there"');
  check('connection error', isWriteInterruption(_offline()));
  check('connection timeout',
      isWriteInterruption(DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.connectionTimeout,
      )));
  check('receive timeout',
      isWriteInterruption(DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.receiveTimeout,
      )));
  check('raw socket error',
      isWriteInterruption(const SocketException('no route to host')));
  check('timeout exception', isWriteInterruption(TimeoutException('slow')));
  check('http exception', isWriteInterruption(const HttpException('closed')));
  check('422 is a refusal', !isWriteInterruption(_status(422)));
  check('500 is a server fault', !isWriteInterruption(_status(500)));
  check('an unrelated error is not a network error',
      !isWriteInterruption(StateError('bug')));
}
