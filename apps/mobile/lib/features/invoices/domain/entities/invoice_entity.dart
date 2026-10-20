/// Invoice domain entities. Pure Dart, no serialization.
/// All money is integer paisa; quantity is the only decimal.
library;

/// One line of an invoice.
class InvoiceLineEntity {
  final int id;
  final int? productId;
  final String description;
  final double quantity;
  final int unitPrice;
  final int discountAmount;
  final int taxRateBps;
  final int taxAmount;
  final int lineTotal;

  const InvoiceLineEntity({
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

/// An invoice. `status` is 'Draft' | 'Sent' | 'Paid' | 'Partial' | 'Overdue'
/// (as serialized by the API).
class InvoiceEntity {
  final int id;
  final String invoiceNumber;
  final int? customerId;
  final String? customerName;
  final int? saleId;
  final String? saleInvoiceNumber;
  final String status;
  final DateTime issueDate;
  final DateTime? dueDate;
  final int subtotal;
  final int discountAmount;
  final int taxAmount;
  final int totalAmount;
  final String? notes;
  final String? terms;
  final bool hasPdf;
  final DateTime? pdfGeneratedAt;
  final List<InvoiceLineEntity> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InvoiceEntity({
    required this.id,
    required this.invoiceNumber,
    this.customerId,
    this.customerName,
    this.saleId,
    this.saleInvoiceNumber,
    required this.status,
    required this.issueDate,
    this.dueDate,
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

  /// True when the invoice was generated from an existing sale.
  bool get isFromSale => saleId != null;
}

/// A page of invoices (mirrors the API's paged envelope).
class InvoicePage {
  final List<InvoiceEntity> data;
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  const InvoicePage({
    required this.data,
    this.page = 1,
    this.pageSize = 100,
    this.totalItems = 0,
    this.totalPages = 0,
    this.hasNext = false,
    this.hasPrev = false,
  });
}

/// A single line being composed in the invoice form (not yet persisted).
/// `productId` is null for a free-text line.
class InvoiceLineDraft {
  final int? productId;
  String description;
  double quantity;
  int unitPrice;
  int discountAmount;
  int taxRateBps;

  InvoiceLineDraft({
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
