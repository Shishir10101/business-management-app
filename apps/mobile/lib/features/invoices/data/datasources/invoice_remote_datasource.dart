import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/invoice_entity.dart';

/// Remote data source for the invoices API.
class InvoiceRemoteDatasource {
  final Dio _dio;

  InvoiceRemoteDatasource(this._dio);

  Future<Map<String, dynamic>> getInvoices({
    int? customerId,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? search,
    int page = 1,
    int pageSize = 100,
  }) async {
    final response = await _dio.get('/invoices', queryParameters: {
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

  Future<Map<String, dynamic>> getInvoice(int id) async {
    final response = await _dio.get('/invoices/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createInvoice({
    int? customerId,
    int? saleId,
    DateTime? issueDate,
    DateTime? dueDate,
    required List<InvoiceLineDraft> items,
    int discountAmount = 0,
    String? notes,
    String? terms,
    String? status,
  }) async {
    final response = await _dio.post('/invoices', data: {
      if (customerId != null) 'customerId': customerId,
      if (saleId != null) 'saleId': saleId,
      if (issueDate != null) 'issueDate': _date(issueDate),
      if (dueDate != null) 'dueDate': _date(dueDate),
      'discountAmount': discountAmount,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (terms != null && terms.isNotEmpty) 'terms': terms,
      if (status != null) 'status': status,
      // When generating from a sale the server copies the sale's lines and
      // reuses its invoice number, so the line items are omitted.
      if (saleId == null) 'items': items.map(_itemJson).toList(),
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateInvoice(
    int id, {
    int? customerId,
    DateTime? issueDate,
    DateTime? dueDate,
    required List<InvoiceLineDraft> items,
    int discountAmount = 0,
    String? notes,
    String? terms,
    String? status,
  }) async {
    final response = await _dio.put('/invoices/$id', data: {
      if (customerId != null) 'customerId': customerId,
      if (issueDate != null) 'issueDate': _date(issueDate),
      if (dueDate != null) 'dueDate': _date(dueDate),
      'discountAmount': discountAmount,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (terms != null && terms.isNotEmpty) 'terms': terms,
      if (status != null) 'status': status,
      'items': items.map(_itemJson).toList(),
    });
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteInvoice(int id) => _dio.delete('/invoices/$id');

  /// Fetches the invoice PDF as raw bytes.
  Future<Uint8List> downloadPdf(int id) async {
    final response = await _dio.get(
      '/invoices/$id/pdf',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data as List<int>);
  }

  static Map<String, dynamic> _itemJson(InvoiceLineDraft i) => {
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

/// Provider for the invoice remote data source.
final invoiceRemoteDatasourceProvider =
    Provider<InvoiceRemoteDatasource>((ref) {
  return InvoiceRemoteDatasource(ref.read(dioProvider));
});
