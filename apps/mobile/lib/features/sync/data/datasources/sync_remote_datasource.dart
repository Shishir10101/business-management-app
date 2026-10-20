import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';

/// Remote data source for the delta sync protocol
/// (GET /sync/pull, POST /sync/push, GET /sync/status).
class SyncRemoteDatasource {
  final Dio _dio;

  SyncRemoteDatasource(this._dio);

  /// Server status: `{ serverTime, storedOperations, pendingConflicts }`.
  Future<Map<String, dynamic>> getStatus() async {
    final response = await _dio.get('/sync/status');
    return response.data as Map<String, dynamic>;
  }

  /// Pulls one page of changes since [since] (omit for a full first pull).
  /// Returns `{ serverTime, since, changes, hasMore }`.
  Future<Map<String, dynamic>> pull({String? since, int limit = 500}) async {
    final response = await _dio.get('/sync/pull', queryParameters: {
      if (since != null && since.isNotEmpty) 'since': since,
      'limit': limit,
    });
    return response.data as Map<String, dynamic>;
  }

  /// Pushes queued operations; returns
  /// `{ serverTime, applied, conflicts, rejected, results }`.
  Future<Map<String, dynamic>> push(
    List<Map<String, dynamic>> operations,
  ) async {
    final response = await _dio.post('/sync/push', data: {
      'operations': operations,
    });
    return response.data as Map<String, dynamic>;
  }
}

/// Provider for the sync remote data source.
final syncRemoteDatasourceProvider = Provider<SyncRemoteDatasource>((ref) {
  return SyncRemoteDatasource(ref.read(dioProvider));
});
