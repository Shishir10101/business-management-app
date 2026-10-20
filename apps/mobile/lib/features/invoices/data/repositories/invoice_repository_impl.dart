import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/invoice_entity.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../datasources/invoice_remote_datasource.dart';

/// Implementation of InvoiceRepository against the Khata API.
class InvoiceRepositoryImpl implements InvoiceRepository {
  final InvoiceRemoteDatasource _remote;

  InvoiceRepositoryImpl(this._remote);

  @override
  Future<InvoicePage> getInvoices({
    int? customerId,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? search,
    int page = 1,
    int pageSize = 100,
  }) async {
    final json = await _remote.getInvoices(
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
  Future<InvoiceEntity> getInvoice(int id) async {
    final json = await _remote.getInvoice(id);
    return _invoiceFromJson(json);
  }

  @override
  Future<InvoiceEntity> createInvoice({
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
    final json = await _remote.createInvoice(
      customerId: customerId,
      saleId: saleId,
      issueDate: issueDate,
      dueDate: dueDate,
      items: items,
      discountAmount: discountAmount,
      notes: notes,
      terms: terms,
      status: status,
    );
    return _invoiceFromJson(json);
  }

  @override
  Future<InvoiceEntity> updateInvoice(
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
    final json = await _remote.updateInvoice(
      id,
      customerId: customerId,
      issueDate: issueDate,
      dueDate: dueDate,
      items: items,
      discountAmount: discountAmount,
      notes: notes,
      terms: terms,
      status: status,
    );
    return _invoiceFromJson(json);
  }

  @override
  Future<void> deleteInvoice(int id) => _remote.deleteInvoice(id);

  @override
  Future<Uint8List> downloadPdf(int id) => _remote.downloadPdf(id);

  // --- mapping ---

  InvoicePage _pageFromJson(Map<String, dynamic> json) {
    final data = (json['data'] as List<dynamic>)
        .map((e) => _invoiceFromJson(e as Map<String, dynamic>))
        .toList();
    final pagination = json['pagination'] as Map<String, dynamic>?;
    return InvoicePage(
      data: data,
      page: pagination?['page'] as int? ?? 1,
      pageSize: pagination?['pageSize'] as int? ?? 100,
      totalItems: pagination?['totalItems'] as int? ?? data.length,
      totalPages: pagination?['totalPages'] as int? ?? 1,
      hasNext: pagination?['hasNext'] as bool? ?? false,
      hasPrev: pagination?['hasPrev'] as bool? ?? false,
    );
  }

  InvoiceEntity _invoiceFromJson(Map<String, dynamic> m) {
    return InvoiceEntity(
      id: m['id'] as int,
      invoiceNumber: m['invoiceNumber'] as String? ?? '',
      customerId: m['customerId'] as int?,
      customerName: m['customerName'] as String?,
      saleId: m['saleId'] as int?,
      saleInvoiceNumber: m['saleInvoiceNumber'] as String?,
      status: m['status'] as String? ?? 'Draft',
      issueDate:
          DateTime.tryParse(m['issueDate'] as String? ?? '') ?? DateTime.now(),
      dueDate: DateTime.tryParse(m['dueDate'] as String? ?? ''),
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

  InvoiceLineEntity _itemFromJson(Map<String, dynamic> m) => InvoiceLineEntity(
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

/// Provider for the invoice repository implementation.
final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  return InvoiceRepositoryImpl(ref.read(invoiceRemoteDatasourceProvider));
});
