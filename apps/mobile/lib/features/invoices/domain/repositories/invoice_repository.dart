import 'dart:typed_data';

import '../entities/invoice_entity.dart';

/// Invoices repository contract. All calls are scoped to the active business
/// on the server.
abstract class InvoiceRepository {
  Future<InvoicePage> getInvoices({
    int? customerId,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? search,
    int page = 1,
    int pageSize = 100,
  });

  Future<InvoiceEntity> getInvoice(int id);

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
  });

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
  });

  Future<void> deleteInvoice(int id);

  /// Downloads the invoice PDF as raw bytes.
  Future<Uint8List> downloadPdf(int id);
}
