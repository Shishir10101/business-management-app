import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';

/// Remote data source for the notification feed, devices and settings
/// (`/api/notifications/...`).
class NotificationRemoteDatasource {
  final Dio _dio;

  NotificationRemoteDatasource(this._dio);

  /// `{ data: [...], pagination: {...} }`
  Future<Map<String, dynamic>> getFeed({
    bool unreadOnly = false,
    String? category,
  }) async {
    final response = await _dio.get('/notifications', queryParameters: {
      if (unreadOnly) 'unreadOnly': true,
      if (category != null && category.isNotEmpty) 'category': category,
      'pageSize': 100,
    });
    return response.data as Map<String, dynamic>;
  }

  /// `{ count: n }`
  Future<int> getUnreadCount() async {
    final response = await _dio.get('/notifications/unread-count');
    final data = response.data as Map<String, dynamic>;
    return (data['count'] as num?)?.toInt() ?? 0;
  }

  Future<void> markRead(int id) async {
    await _dio.post('/notifications/$id/read');
  }

  Future<int> markAllRead() async {
    final response = await _dio.post('/notifications/read-all');
    final data = response.data as Map<String, dynamic>;
    return (data['markedRead'] as num?)?.toInt() ?? 0;
  }

  Future<void> delete(int id) async {
    await _dio.delete('/notifications/$id');
  }

  Future<Map<String, dynamic>> registerDevice({
    required String token,
    required String platform,
  }) async {
    final response = await _dio.post('/notifications/devices', data: {
      'token': token,
      'platform': platform,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<void> unregisterDevice(String token) async {
    await _dio
        .delete('/notifications/devices', queryParameters: {'token': token});
  }

  Future<List<dynamic>> getDevices() async {
    final response = await _dio.get('/notifications/devices');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getSettings() async {
    final response = await _dio.get('/notifications/settings');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateSettings(
      Map<String, dynamic> settings) async {
    final response = await _dio.put('/notifications/settings', data: settings);
    return response.data as Map<String, dynamic>;
  }
}

/// Provider for the notification remote data source.
final notificationRemoteDatasourceProvider =
    Provider<NotificationRemoteDatasource>((ref) {
  return NotificationRemoteDatasource(ref.read(dioProvider));
});
