import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';

/// Remote data source for reminders (`/api/reminders/...`).
///
/// `dueAt` travels as a Nepal local wall-clock string (`yyyy-MM-ddTHH:mm`),
/// which is what the API expects; it converts to UTC for storage itself.
class ReminderRemoteDatasource {
  final Dio _dio;

  ReminderRemoteDatasource(this._dio);

  Future<Map<String, dynamic>> list({String? status}) async {
    final response = await _dio.get('/reminders', queryParameters: {
      if (status != null && status.isNotEmpty) 'status': status,
      'pageSize': 200,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getById(int id) async {
    final response = await _dio.get('/reminders/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    final response = await _dio.post('/reminders', data: body);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> body) async {
    final response = await _dio.put('/reminders/$id', data: body);
    return response.data as Map<String, dynamic>;
  }

  Future<void> complete(int id) async {
    await _dio.post('/reminders/$id/complete');
  }

  Future<void> dismiss(int id) async {
    await _dio.post('/reminders/$id/dismiss');
  }

  Future<void> delete(int id) async {
    await _dio.delete('/reminders/$id');
  }

  /// `{ fired: n }`
  Future<int> processDue() async {
    final response = await _dio.post('/reminders/process-due');
    final data = response.data as Map<String, dynamic>;
    return (data['fired'] as num?)?.toInt() ?? 0;
  }
}

/// Provider for the reminder remote data source.
final reminderRemoteDatasourceProvider =
    Provider<ReminderRemoteDatasource>((ref) {
  return ReminderRemoteDatasource(ref.read(dioProvider));
});
