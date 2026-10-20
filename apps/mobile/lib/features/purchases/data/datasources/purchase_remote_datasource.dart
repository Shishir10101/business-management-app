import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/purchase_entity.dart';

/// Remote data source for the purchases API.
class PurchaseRemoteDatasource {
  final Dio _dio;

  PurchaseRemoteDatasource(this._dio);

  Future<Map<String, dynamic>> getPurchases({
    int? supplierId,
    String? purchaseType,
    String? paymentStatus,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get('/purchases', queryParameters: {
      if (supplierId != null) 'supplierId': supplierId,
      if (purchaseType != null) 'purchaseType': purchaseType,
      if (paymentStatus != null) 'paymentStatus': paymentStatus,
      if (dateFrom != null) 'dateFrom': _date(dateFrom),
      if (dateTo != null) 'dateTo': _date(dateTo),
      if (search != null && search.isNotEmpty) 'search': search,
      'page': page,
      'pageSize': pageSize,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getPurchase(int id) async {
    final response = await _dio.get('/purchases/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createPurchase({
    int? supplierId,
    required String purchaseType,
    DateTime? purchaseDate,
    required List<PurchaseLineDraft> items,
    int discountAmount = 0,
    int paidAmount = 0,
    String? notes,
  }) async {
    final response = await _dio.post('/purchases', data: {
      if (supplierId != null) 'supplierId': supplierId,
      'purchaseType': purchaseType,
      if (purchaseDate != null) 'purchaseDate': _date(purchaseDate),
      'discountAmount': discountAmount,
      'paidAmount': paidAmount,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'items': items
          .map((i) => {
                'productId': i.productId,
                'quantity': i.quantity,
                'unitPrice': i.unitPrice,
                'discountAmount': i.discountAmount,
                'taxRateBps': i.taxRateBps,
              })
          .toList(),
    });
    return response.data as Map<String, dynamic>;
  }

  Future<void> deletePurchase(int id) => _dio.delete('/purchases/$id');

  static String _date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Provider for the purchase remote data source.
final purchaseRemoteDatasourceProvider =
    Provider<PurchaseRemoteDatasource>((ref) {
  return PurchaseRemoteDatasource(ref.read(dioProvider));
});
