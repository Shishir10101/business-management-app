import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/quotation_entity.dart';
import '../../domain/repositories/quotation_repository.dart';
import '../datasources/quotation_remote_datasource.dart';

/// Implementation of QuotationRepository against the Khata API.
class QuotationRepositoryImpl implements QuotationRepository {
  final QuotationRemoteDatasource _remote;

  QuotationRepositoryImpl(this._remote);

  @override
  Future<QuotationPage> getQuotations({
    int? customerId,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? search,
    int page = 1,
    int pageSize = 100,
  }) async {
    final json = await _remote.getQuotations(
      customerId: customerId,
      status: status,
      dateFrom: dateFrom,
      dateTo: dateTo,
      search: search,
      page: page,
      pageSize: pageSize,
    );
    return _pageFromJson(json);
  }

  @override
  Future<QuotationEntity> getQuotation(int id) async {
    final json = await _remote.getQuotation(id);
    return _quotationFromJson(json);
  }

  @override
  Future<QuotationEntity> createQuotation({
    int? customerId,
    DateTime? issueDate,
    DateTime? validUntil,
    required List<QuotationLineDraft> items,
    int discountAmount = 0,
    String? notes,
    String? terms,
    String? status,
  }) async {
    final json = await _remote.createQuotation(
      customerId: customerId,
      issueDate: issueDate,
      validUntil: validUntil,
      items: items,
      discountAmount: discountAmount,
      notes: notes,
      terms: terms,
      status: status,
    );
    return _quotationFromJson(json);
  }

  @override
  Future<QuotationEntity> updateQuotation(
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
    final json = await _remote.updateQuotation(
      id,
      customerId: customerId,
      issueDate: issueDate,
      validUntil: validUntil,
      items: items,
      discountAmount: discountAmount,
      notes: notes,
      terms: terms,
      status: status,
    );
    return _quotationFromJson(json);
  }

  @override
  Future<void> deleteQuotation(int id) => _remote.deleteQuotation(id);

  @override
  Future<Uint8List> downloadPdf(int id) => _remote.downloadPdf(id);

  @override
  Future<Map<String, dynamic>> convertToSale(
    int id, {
    required String saleType,
    int paidAmount = 0,
    DateTime? saleDate,
    String? notes,
  }) {
    return _remote.convertToSale(
      id,
      saleType: saleType,
      paidAmount: paidAmount,
      saleDate: saleDate,
      notes: notes,
    );
  }

  // --- mapping ---

  QuotationPage _pageFromJson(Map<String, dynamic> json) {
    final data = (json['data'] as List<dynamic>)
        .map((e) => _quotationFromJson(e as Map<String, dynamic>))
        .toList();
    final pagination = json['pagination'] as Map<String, dynamic>?;
    return QuotationPage(
      data: data,
      page: pagination?['page'] as int? ?? 1,
      pageSize: pagination?['pageSize'] as int? ?? 100,
      totalItems: pagination?['totalItems'] as int? ?? data.length,
      totalPages: pagination?['totalPages'] as int? ?? 1,
      hasNext: pagination?['hasNext'] as bool? ?? false,
      hasPrev: pagination?['hasPrev'] as bool? ?? false,
    );
  }

  QuotationEntity _quotationFromJson(Map<String, dynamic> m) {
    return QuotationEntity(
      id: m['id'] as int,
      quoteNumber: m['quoteNumber'] as String? ?? '',
      customerId: m['customerId'] as int?,
      customerName: m['customerName'] as String?,
      convertedSaleId: m['convertedSaleId'] as int?,
      status: m['status'] as String? ?? 'Draft',
      issueDate:
          DateTime.tryParse(m['issueDate'] as String? ?? '') ?? DateTime.now(),
      validUntil: DateTime.tryParse(m['validUntil'] as String? ?? ''),
      subtotal: m['subtotal'] as int? ?? 0,
      discountAmount: m['discountAmount'] as int? ?? 0,
      taxAmount: m['taxAmount'] as int? ?? 0,
      totalAmount: m['totalAmount'] as int? ?? 0,
      notes: m['notes'] as String?,
      terms: m['terms'] as String?,
      hasPdf: m['hasPdf'] as bool? ?? false,
      pdfGeneratedAt: DateTime.tryParse(m['pdfGeneratedAt'] as String? ?? ''),
      items: ((m['items'] as List<dynamic>?) ?? const [])
          .map((e) => _itemFromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt:
          DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(m['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  QuotationLineEntity _itemFromJson(Map<String, dynamic> m) =>
      QuotationLineEntity(
        id: m['id'] as int? ?? 0,
        productId: m['productId'] as int?,
        description: m['description'] as String? ?? '',
        quantity: (m['quantity'] as num?)?.toDouble() ?? 0,
        unitPrice: m['unitPrice'] as int? ?? 0,
        discountAmount: m['discountAmount'] as int? ?? 0,
        taxRateBps: m['taxRateBps'] as int? ?? 0,
        taxAmount: m['taxAmount'] as int? ?? 0,
        lineTotal: m['lineTotal'] as int? ?? 0,
      );
}

/// Provider for the quotation repository implementation.
final quotationRepositoryProvider = Provider<QuotationRepository>((ref) {
  return QuotationRepositoryImpl(ref.read(quotationRemoteDatasourceProvider));
});
