import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';

/// Remote data source for the payments API.
class PaymentRemoteDatasource {
  final Dio _dio;

  PaymentRemoteDatasource(this._dio);

  Future<Map<String, dynamic>> getPayments({
    String? partyType,
    int? partyId,
    String? direction,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? search,
    int page = 1,
    int pageSize = 100,
  }) async {
    final response = await _dio.get('/payments', queryParameters: {
      if (partyType != null) 'partyType': partyType,
      if (partyId != null) 'partyId': partyId,
      if (direction != null) 'direction': direction,
      if (dateFrom != null) 'dateFrom': _date(dateFrom),
      if (dateTo != null) 'dateTo': _date(dateTo),
      if (search != null && search.isNotEmpty) 'search': search,
      'page': page,
      'pageSize': pageSize,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSummary() async {
    final response = await _dio.get('/payments/summary');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createPayment({
    required String partyType,
    required int partyId,
    required int amount,
    String? direction,
    DateTime? paymentDate,
    int? paymentMethodId,
    String? methodCode,
    String? reference,
    String? notes,
    int? saleId,
    int? purchaseId,
  }) async {
    final response = await _dio.post('/payments', data: {
      'partyType': partyType,
      'partyId': partyId,
      'amount': amount,
      if (direction != null) 'direction': direction,
      if (paymentDate != null) 'paymentDate': _date(paymentDate),
      if (paymentMethodId != null) 'paymentMethodId': paymentMethodId,
      if (methodCode != null && methodCode.isNotEmpty) 'methodCode': methodCode,
      if (reference != null && reference.isNotEmpty) 'reference': reference,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (saleId != null) 'saleId': saleId,
      if (purchaseId != null) 'purchaseId': purchaseId,
    });
    return response.data as Map<String, dynamic>;
  }

  /// Payment methods are returned as a plain JSON array (not paged).
  Future<List<dynamic>> getMethods() async {
    final response = await _dio.get('/payment-methods');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createMethod({
    required String name,
    String? code,
    String? description,
    bool isDefault = false,
  }) async {
    final response = await _dio.post('/payment-methods', data: {
      'name': name,
      if (code != null && code.isNotEmpty) 'code': code,
      if (description != null && description.isNotEmpty)
        'description': description,
      'isDefault': isDefault,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateMethod(
    int id, {
    required String name,
    String? code,
    String? description,
    bool isActive = true,
    bool isDefault = false,
  }) async {
    final response = await _dio.put('/payment-methods/$id', data: {
      'name': name,
      if (code != null && code.isNotEmpty) 'code': code,
      if (description != null && description.isNotEmpty)
        'description': description,
      'isActive': isActive,
      'isDefault': isDefault,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteMethod(int id) => _dio.delete('/payment-methods/$id');

  static String _date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Provider for the payment remote data source.
final paymentRemoteDatasourceProvider =
    Provider<PaymentRemoteDatasource>((ref) {
  return PaymentRemoteDatasource(ref.read(dioProvider));
});
