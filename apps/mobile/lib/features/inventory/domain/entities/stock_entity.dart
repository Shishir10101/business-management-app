/// Stock domain entities — pure Dart, no serialization.

/// One entry of a product's append-only stock movement ledger.
/// Signed quantity: positive = in, negative = out. Movement type arrives as
/// a string ("Opening", "AdjustmentIn", ...) from the API.
class StockMovementEntity {
  final int id;
  final int productId;
  final String productName;
  final String movementType;
  final double quantity;
  final double balanceAfter;
  final String? referenceType;
  final int? referenceId;
  final String? notes;
  final DateTime movementDate;
  final DateTime createdAt;

  const StockMovementEntity({
    required this.id,
    required this.productId,
    required this.productName,
    required this.movementType,
    required this.quantity,
    required this.balanceAfter,
    this.referenceType,
    this.referenceId,
    this.notes,
    required this.movementDate,
    required this.createdAt,
  });

  bool get isCredit => quantity > 0;
}

/// Result of a stock adjustment: the updated stock row plus the appended movement.
class StockAdjustmentResult {
  final int productId;
  final String productName;
  final double quantity;
  final double minQuantity;
  final StockMovementEntity movement;

  const StockAdjustmentResult({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.minQuantity,
    required this.movement,
  });
}

/// One page of stock movements with pagination metadata.
class MovementPage {
  final List<StockMovementEntity> data;
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  const MovementPage({
    required this.data,
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });
}
