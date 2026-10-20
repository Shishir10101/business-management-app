import '../../../products/domain/entities/product_entity.dart';
import '../entities/stock_entity.dart';

/// Inventory repository contract (domain layer): stock levels, adjustments,
/// movement history and low-stock alerts.
abstract class InventoryRepository {
  /// Stock list (products with their current quantity).
  Future<ProductPage> getInventory({
    String? search,
    bool lowStockOnly = false,
    String? sortBy,
    int page = 1,
    int pageSize = 20,
  });

  /// Products at or below their minimum quantity.
  Future<List<ProductEntity>> getLowStock();

  /// Applies a signed stock adjustment (positive = in, negative = out).
  Future<StockAdjustmentResult> adjustStock(
    int productId, {
    required double quantity,
    String? notes,
  });

  /// Append-only movement history for a product, newest first.
  Future<MovementPage> getMovements(
    int productId, {
    int page = 1,
    int pageSize = 20,
  });
}
