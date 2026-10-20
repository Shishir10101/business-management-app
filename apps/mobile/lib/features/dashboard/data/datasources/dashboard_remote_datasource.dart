import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';

/// Remote data source for the dashboard API.
class DashboardRemoteDatasource {
  final Dio _dio;

  DashboardRemoteDatasource(this._dio);

  Future<Map<String, dynamic>> getDashboard() async {
    final response = await _dio.get('/reports/dashboard');
    return response.data as Map<String, dynamic>;
  }
}

/// Provider for the dashboard remote data source.
final dashboardRemoteDatasourceProvider =
    Provider<DashboardRemoteDatasource>((ref) {
  return DashboardRemoteDatasource(ref.read(dioProvider));
});
