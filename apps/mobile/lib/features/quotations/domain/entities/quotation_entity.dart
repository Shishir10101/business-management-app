/// Quotation domain entities. Pure Dart, no serialization.
/// All money is integer paisa; quantity is the only decimal.
library;

/// One line of a quotation.
class QuotationLineEntity {
  final int id;
  final int? productId;
  final String description;
  final double quantity;
  final int unitPrice;
  final int discountAmount;
  final int taxRateBps;
  final int taxAmount;
  final int lineTotal;

  const QuotationLineEntity({
    required this.id,
    this.productId,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.discountAmount = 0,
    this.taxRateBps = 0,
    this.taxAmount = 0,
    required this.lineTotal,
  });
}

/// A quotation. `status` is 'Draft' | 'Sent' | 'Accepted' | 'Rejected' |
/// 'Expired' (as serialized by the API).
class QuotationEntity {
  final int id;
  final String quoteNumber;
  final int? customerId;
  final String? customerName;
  final int? convertedSaleId;
  final String status;
  final DateTime issueDate;
  final DateTime? validUntil;
  final int subtotal;
  final int discountAmount;
  final int taxAmount;
  final int totalAmount;
  final String? notes;
  final String? terms;
  final bool hasPdf;
  final DateTime? pdfGeneratedAt;
  final List<QuotationLineEntity> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  const QuotationEntity({
    required this.id,
    required this.quoteNumber,
    this.customerId,
    this.customerName,
    this.convertedSaleId,
    required this.status,
    required this.issueDate,
    this.validUntil,
    required this.subtotal,
    this.discountAmount = 0,
    this.taxAmount = 0,
    required this.totalAmount,
    this.notes,
    this.terms,
    this.hasPdf = false,
    this.pdfGeneratedAt,
    this.items = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// True once the quotation has been converted into a sale.
  bool get isConverted => convertedSaleId != null;

  /// A converted, rejected or expired quotation can no longer be converted.
  bool get canConvert =>
      !isConverted && status != 'Rejected' && status != 'Expired';
}

/// A page of quotations (mirrors the API's paged envelope).
class QuotationPage {
  final List<QuotationEntity> data;
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  const QuotationPage({
    required this.data,
    this.page = 1,
    this.pageSize = 100,
    this.totalItems = 0,
    this.totalPages = 0,
    this.hasNext = false,
    this.hasPrev = false,
  });
}

/// A single line being composed in the quotation form (not yet persisted).
/// `productId` is null for a free-text line.
class QuotationLineDraft {
  final int? productId;
  String description;
  double quantity;
  int unitPrice;
  int discountAmount;
  int taxRateBps;

  QuotationLineDraft({
    this.productId,
    this.description = '',
    this.quantity = 1,
    this.unitPrice = 0,
    this.discountAmount = 0,
    this.taxRateBps = 0,
  });

  /// Mirrors the server's per-line math exactly (integer paisa).
  int get gross => (unitPrice * quantity).round();

  int get taxAmount {
    final net = gross - discountAmount;
    return (net * taxRateBps / 10000).round();
  }

  int get lineTotal => gross - discountAmount + taxAmount;
}
