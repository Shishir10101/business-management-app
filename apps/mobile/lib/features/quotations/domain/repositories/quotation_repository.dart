import 'dart:typed_data';

import '../entities/quotation_entity.dart';

/// Quotations repository contract. All calls are scoped to the active business
/// on the server.
abstract class QuotationRepository {
  Future<QuotationPage> getQuotations({
    int? customerId,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? search,
    int page = 1,
    int pageSize = 100,
  });

  Future<QuotationEntity> getQuotation(int id);

  Future<QuotationEntity> createQuotation({
    int? customerId,
    DateTime? issueDate,
    DateTime? validUntil,
    required List<QuotationLineDraft> items,
    int discountAmount = 0,
    String? notes,
    String? terms,
    String? status,
  });

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
  });

  Future<void> deleteQuotation(int id);

  /// Downloads the quotation PDF as raw bytes.
  Future<Uint8List> downloadPdf(int id);

  /// Converts the quotation into a sale and returns the created SaleDto JSON.
  Future<Map<String, dynamic>> convertToSale(
    int id, {
    required String saleType,
    int paidAmount = 0,
    DateTime? saleDate,
    String? notes,
  });
}
