import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/quotation_entity.dart';

/// Remote data source for the quotations API.
class QuotationRemoteDatasource {
  final Dio _dio;

  QuotationRemoteDatasource(this._dio);

  Future<Map<String, dynamic>> getQuotations({
    int? customerId,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? search,
    int page = 1,
    int pageSize = 100,
  }) async {
    final response = await _dio.get('/quotations', queryParameters: {
      if (customerId != null) 'customerId': customerId,
      if (status != null) 'status': status,
      if (dateFrom != null) 'dateFrom': _date(dateFrom),
      if (dateTo != null) 'dateTo': _date(dateTo),
      if (search != null && search.isNotEmpty) 'search': search,
      'page': page,
      'pageSize': pageSize,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getQuotation(int id) async {
    final response = await _dio.get('/quotations/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createQuotation({
    int? customerId,
    DateTime? issueDate,
    DateTime? validUntil,
    required List<QuotationLineDraft> items,
    int discountAmount = 0,
    String? notes,
    String? terms,
    String? status,
  }) async {
    final response = await _dio.post('/quotations', data: {
      if (customerId != null) 'customerId': customerId,
      if (issueDate != null) 'issueDate': _date(issueDate),
      if (validUntil != null) 'validUntil': _date(validUntil),
      'discountAmount': discountAmount,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (terms != null && terms.isNotEmpty) 'terms': terms,
      if (status != null) 'status': status,
      'items': items.map(_itemJson).toList(),
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateQuotation(
    int id, {
    int? customerId,
    DateTime? issueDate,
    DateTime? validUntil,
    required List<QuotationLineDraft> items,
    int discountAmount = 0,
    String? notes,
    String? terms,
    String? status,
  }) async {
    final response = await _dio.put('/quotations/$id', data: {
      if (customerId != null) 'customerId': customerId,
      if (issueDate != null) 'issueDate': _date(issueDate),
      if (validUntil != null) 'validUntil': _date(validUntil),
      'discountAmount': discountAmount,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (terms != null && terms.isNotEmpty) 'terms': terms,
      if (status != null) 'status': status,
      'items': items.map(_itemJson).toList(),
    });
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteQuotation(int id) => _dio.delete('/quotations/$id');

  /// Fetches the quotation PDF as raw bytes.
  Future<Uint8List> downloadPdf(int id) async {
    final response = await _dio.get(
      '/quotations/$id/pdf',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data as List<int>);
  }

  /// Converts the quotation into a sale; the response is the created SaleDto.
  Future<Map<String, dynamic>> convertToSale(
    int id, {
    required String saleType,
    int paidAmount = 0,
    DateTime? saleDate,
    String? notes,
  }) async {
    final response = await _dio.post('/quotations/$id/convert', data: {
      'saleType': saleType,
      'paidAmount': paidAmount,
      if (saleDate != null) 'saleDate': _date(saleDate),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return response.data as Map<String, dynamic>;
  }

  static Map<String, dynamic> _itemJson(QuotationLineDraft i) => {
        if (i.productId != null) 'productId': i.productId,
        'description': i.description,
        'quantity': i.quantity,
        'unitPrice': i.unitPrice,
        'discountAmount': i.discountAmount,
        'taxRateBps': i.taxRateBps,
      };

  static String _date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Provider for the quotation remote data source.
final quotationRemoteDatasourceProvider =
    Provider<QuotationRemoteDatasource>((ref) {
  return QuotationRemoteDatasource(ref.read(dioProvider));
});
