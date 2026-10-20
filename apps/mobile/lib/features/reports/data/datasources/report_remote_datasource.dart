import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';

/// Remote data source for the reports API.
class ReportRemoteDatasource {
  final Dio _dio;

  ReportRemoteDatasource(this._dio);

  Future<Map<String, dynamic>> getSalesReport({
    required DateTime from,
    required DateTime to,
    String groupBy = 'day',
    int top = 10,
  }) async {
    final response = await _dio.get('/reports/sales', queryParameters: {
      'dateFrom': _date(from),
      'dateTo': _date(to),
      'groupBy': groupBy,
      'top': top,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getPurchaseReport({
    required DateTime from,
    required DateTime to,
    String groupBy = 'day',
    int top = 10,
  }) async {
    final response = await _dio.get('/reports/purchases', queryParameters: {
      'dateFrom': _date(from),
      'dateTo': _date(to),
      'groupBy': groupBy,
      'top': top,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getExpenseReport({
    required DateTime from,
    required DateTime to,
    String groupBy = 'day',
  }) async {
    final response = await _dio.get('/reports/expenses', queryParameters: {
      'dateFrom': _date(from),
      'dateTo': _date(to),
      'groupBy': groupBy,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getIncomeReport({
    required DateTime from,
    required DateTime to,
    String groupBy = 'day',
  }) async {
    final response = await _dio.get('/reports/income', queryParameters: {
      'dateFrom': _date(from),
      'dateTo': _date(to),
      'groupBy': groupBy,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getProfitLoss({
    required DateTime from,
    required DateTime to,
  }) async {
    final response = await _dio.get('/reports/profit-loss', queryParameters: {
      'dateFrom': _date(from),
      'dateTo': _date(to),
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getStockReport({
    bool lowStockOnly = false,
    String? search,
  }) async {
    final response = await _dio.get('/reports/stock', queryParameters: {
      'lowStockOnly': lowStockOnly,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getReceivablePayable() async {
    final response = await _dio.get('/reports/receivable-payable');
    return response.data as Map<String, dynamic>;
  }

  /// Fetches a report export as raw CSV bytes.
  Future<Uint8List> downloadCsv({
    required String type,
    required DateTime from,
    required DateTime to,
  }) async {
    final response = await _dio.get(
      '/reports/export',
      queryParameters: {
        'type': type,
        'dateFrom': _date(from),
        'dateTo': _date(to),
      },
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data as List<int>);
  }

  static String _date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Provider for the report remote data source.
final reportRemoteDatasourceProvider = Provider<ReportRemoteDatasource>((ref) {
  return ReportRemoteDatasource(ref.read(dioProvider));
});
