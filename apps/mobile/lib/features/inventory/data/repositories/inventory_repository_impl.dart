import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../products/domain/entities/product_entity.dart';
import '../datasources/inventory_remote_datasource.dart';
import '../../domain/entities/stock_entity.dart';
import '../../domain/repositories/inventory_repository.dart';

/// Implementation of InventoryRepository against the Khata API.
class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryRemoteDatasource _remote;

  InventoryRepositoryImpl(this._remote);

  @override
  Future<ProductPage> getInventory({
    String? search,
    bool lowStockOnly = false,
    String? sortBy,
    int page = 1,
    int pageSize = 20,
  }) async {
    final json = await _remote.getInventory(
      search: search,
      lowStockOnly: lowStockOnly,
      sortBy: sortBy,
      page: page,
      pageSize: pageSize,
    );
    return _productPageFromJson(json);
  }

  @override
  Future<List<ProductEntity>> getLowStock() async {
    final list = await _remote.getLowStock();
    return list
        .map((e) => _productFromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<StockAdjustmentResult> adjustStock(
    int productId, {
    required double quantity,
    String? notes,
  }) async {
    final json = await _remote.adjustStock(
      productId,
      quantity: quantity,
      notes: notes,
    );
    final movementJson = json['movement'] as Map<String, dynamic>;
    return StockAdjustmentResult(
      productId: json['productId'] as int,
      productName: json['productName'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      minQuantity: (json['minQuantity'] as num).toDouble(),
      movement: StockMovementEntity(
        id: movementJson['id'] as int,
        productId: movementJson['productId'] as int,
        productName: movementJson['productName'] as String,
        movementType: movementJson['movementType'] as String,
        quantity: (movementJson['quantity'] as num).toDouble(),
        balanceAfter: (movementJson['balanceAfter'] as num).toDouble(),
        referenceType: movementJson['referenceType'] as String?,
        referenceId: movementJson['referenceId'] as int?,
        notes: movementJson['notes'] as String?,
        movementDate:
            DateTime.tryParse(movementJson['movementDate'] as String? ?? '') ??
                DateTime.now(),
        createdAt:
            DateTime.tryParse(movementJson['createdAt'] as String? ?? '') ??
                DateTime.now(),
      ),
    );
  }

  @override
  Future<MovementPage> getMovements(
    int productId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final json =
        await _remote.getMovements(productId, page: page, pageSize: pageSize);
    final data = (json['data'] as List<dynamic>).map((e) {
      final map = e as Map<String, dynamic>;
      return StockMovementEntity(
        id: map['id'] as int,
        productId: map['productId'] as int,
        productName: map['productName'] as String,
        movementType: map['movementType'] as String,
        quantity: (map['quantity'] as num).toDouble(),
        balanceAfter: (map['balanceAfter'] as num).toDouble(),
        referenceType: map['referenceType'] as String?,
        referenceId: map['referenceId'] as int?,
        notes: map['notes'] as String?,
        movementDate: DateTime.tryParse(map['movementDate'] as String? ?? '') ??
            DateTime.now(),
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
    }).toList();
    final pagination = json['pagination'] as Map<String, dynamic>;
    return MovementPage(
      data: data,
      page: pagination['page'] as int? ?? 1,
      pageSize: pagination['pageSize'] as int? ?? 20,
      totalItems: pagination['totalItems'] as int? ?? data.length,
      totalPages: pagination['totalPages'] as int? ?? 1,
      hasNext: pagination['hasNext'] as bool? ?? false,
      hasPrev: pagination['hasPrev'] as bool? ?? false,
    );
  }

  // --- mapping (mirrors ProductRepositoryImpl) ---

  ProductEntity _productFromJson(Map<String, dynamic> map) {
    return ProductEntity(
      id: map['id'] as int,
      name: map['name'] as String,
      categoryId: map['categoryId'] as int?,
      categoryName: map['categoryName'] as String?,
      unitId: map['unitId'] as int?,
      unitShortName: map['unitShortName'] as String?,
      sku: map['sku'] as String?,
      barcode: map['barcode'] as String?,
      description: map['description'] as String?,
      costPrice: map['costPrice'] as int? ?? 0,
      sellingPrice: map['sellingPrice'] as int? ?? 0,
      wholesalePrice: map['wholesalePrice'] as int?,
      taxRateBps: map['taxRateBps'] as int? ?? 0,
      imageUrl: map['imageUrl'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      stockQuantity: (map['stockQuantity'] as num?)?.toDouble() ?? 0,
      minQuantity: (map['minQuantity'] as num?)?.toDouble() ?? 0,
      isLowStock: map['isLowStock'] as bool? ?? false,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? ''),
    );
  }

  ProductPage _productPageFromJson(Map<String, dynamic> json) {
    final data = (json['data'] as List<dynamic>)
        .map((e) => _productFromJson(e as Map<String, dynamic>))
        .toList();
    final pagination = json['pagination'] as Map<String, dynamic>;
    return ProductPage(
      data: data,
      page: pagination['page'] as int? ?? 1,
      pageSize: pagination['pageSize'] as int? ?? 20,
      totalItems: pagination['totalItems'] as int? ?? data.length,
      totalPages: pagination['totalPages'] as int? ?? 1,
      hasNext: pagination['hasNext'] as bool? ?? false,
      hasPrev: pagination['hasPrev'] as bool? ?? false,
    );
  }
}

/// Provider for the inventory repository implementation.
final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepositoryImpl(ref.read(inventoryRemoteDatasourceProvider));
});
