import '../entities/sale_entity.dart';

/// Sales repository contract. All calls are scoped to the active business on
/// the server.
abstract class SaleRepository {
  Future<SalePage> getSales({
    int? customerId,
    String? saleType,
    String? paymentStatus,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? search,
    int page = 1,
    int pageSize = 20,
  });

  Future<SaleEntity> getSale(int id);

  Future<SaleEntity> createSale({
    int? customerId,
    required String saleType,
    DateTime? saleDate,
    required List<SaleLineDraft> items,
    int discountAmount = 0,
    int paidAmount = 0,
    String? notes,
  });

  Future<void> deleteSale(int id);
}
