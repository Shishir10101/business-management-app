import '../entities/purchase_entity.dart';

/// Purchases repository contract. All calls are scoped to the active business
/// on the server.
abstract class PurchaseRepository {
  Future<PurchasePage> getPurchases({
    int? supplierId,
    String? purchaseType,
    String? paymentStatus,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? search,
    int page = 1,
    int pageSize = 20,
  });

  Future<PurchaseEntity> getPurchase(int id);

  Future<PurchaseEntity> createPurchase({
    int? supplierId,
    required String purchaseType,
    DateTime? purchaseDate,
    required List<PurchaseLineDraft> items,
    int discountAmount = 0,
    int paidAmount = 0,
    String? notes,
  });

  Future<void> deletePurchase(int id);
}
