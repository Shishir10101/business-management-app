import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/offline/offline_providers.dart';
import '../../../../core/offline/offline_queue.dart';
import '../../domain/entities/sale_entity.dart';

/// Remote data source for the sales API.
///
/// Creating a sale goes through an [OfflineQueue] — a shop that loses signal
/// mid-transaction still records the sale. Editing and deleting a sale stay
/// online-only: the server's push protocol refuses those operations because
/// stock movements and ledger entries are derived from the original document.
class SaleRemoteDatasource {
  final Dio _dio;
  final OfflineQueue _queue;

  SaleRemoteDatasource(this._dio, {OfflineQueue? queue})
      : _queue = queue ?? OfflineQueue.disabled();

  Future<Map<String, dynamic>> getSales({
    int? customerId,
    String? saleType,
    String? paymentStatus,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get('/sales', queryParameters: {
      if (customerId != null) 'customerId': customerId,
      if (saleType != null) 'saleType': saleType,
      if (paymentStatus != null) 'paymentStatus': paymentStatus,
      if (dateFrom != null) 'dateFrom': _date(dateFrom),
      if (dateTo != null) 'dateTo': _date(dateTo),
      if (search != null && search.isNotEmpty) 'search': search,
      'page': page,
      'pageSize': pageSize,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSale(int id) async {
    final response = await _dio.get('/sales/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createSale({
    int? customerId,
    required String saleType,
    DateTime? saleDate,
    required List<SaleLineDraft> items,
    int discountAmount = 0,
    int paidAmount = 0,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      if (customerId != null) 'customerId': customerId,
      'saleType': saleType,
      if (saleDate != null) 'saleDate': _date(saleDate),
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
    };
    final result = await _queue.create(
      entityType: 'sale',
      body: body,
      send: () async =>
          (await _dio.post('/sales', data: body)).data as Map<String, dynamic>,
    );
    return result.value!;
  }

  Future<void> deleteSale(int id) => _dio.delete('/sales/$id');

  static String _date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Provider for the sale remote data source.
final saleRemoteDatasourceProvider = Provider<SaleRemoteDatasource>((ref) {
  return SaleRemoteDatasource(
    ref.read(dioProvider),
    queue: ref.read(offlineQueueProvider),
  );
});
