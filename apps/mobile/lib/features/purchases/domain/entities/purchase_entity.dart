/// Purchases domain entities. Pure Dart, no serialization.
/// All money is integer paisa; quantity is the only decimal.
library;

/// One line of a purchase.
class PurchaseItemEntity {
  final int id;
  final int productId;
  final String productName;
  final double quantity;
  final int unitPrice;
  final int discountAmount;
  final int taxRateBps;
  final int taxAmount;
  final int lineTotal;

  const PurchaseItemEntity({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.discountAmount = 0,
    this.taxRateBps = 0,
    this.taxAmount = 0,
    required this.lineTotal,
  });
}

/// A purchase. `purchaseType` is 'Cash' | 'Credit' | 'Partial';
/// `paymentStatus` is 'Paid' | 'Partial' | 'Unpaid' (as serialized by the API).
class PurchaseEntity {
  final int id;
  final String billNumber;
  final int? supplierId;
  final String? supplierName;
  final String purchaseType;
  final String paymentStatus;
  final DateTime purchaseDate;
  final int subtotal;
  final int discountAmount;
  final int taxAmount;
  final int totalAmount;
  final int paidAmount;
  final int dueAmount;
  final String? notes;
  final List<PurchaseItemEntity> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PurchaseEntity({
    required this.id,
    required this.billNumber,
    this.supplierId,
    this.supplierName,
    required this.purchaseType,
    required this.paymentStatus,
    required this.purchaseDate,
    required this.subtotal,
    this.discountAmount = 0,
    this.taxAmount = 0,
    required this.totalAmount,
    this.paidAmount = 0,
    required this.dueAmount,
    this.notes,
    this.items = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPaid => paymentStatus == 'Paid';
  bool get isUnpaid => paymentStatus == 'Unpaid';
}

/// A page of purchases (mirrors the API's paged envelope).
class PurchasePage {
  final List<PurchaseEntity> data;
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  const PurchasePage({
    required this.data,
    this.page = 1,
    this.pageSize = 20,
    this.totalItems = 0,
    this.totalPages = 0,
    this.hasNext = false,
    this.hasPrev = false,
  });
}

/// A single line being composed in the purchase form (not yet persisted).
class PurchaseLineDraft {
  final int productId;
  final String productName;
  double quantity;
  int unitPrice;
  int discountAmount;
  int taxRateBps;

  PurchaseLineDraft({
    required this.productId,
    required this.productName,
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
