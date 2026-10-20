/// Product domain entities — pure Dart, no serialization.

/// Product category (supports one level of nesting via parentId).
class CategoryEntity {
  final int id;
  final String name;
  final String? description;
  final int? parentId;
  final String? parentName;
  final bool isActive;
  final int productCount;

  const CategoryEntity({
    required this.id,
    required this.name,
    this.description,
    this.parentId,
    this.parentName,
    this.isActive = true,
    this.productCount = 0,
  });
}

/// Unit of measure (pcs, kg, box, dozen...). Unique per business by name.
class UnitEntity {
  final int id;
  final String name;
  final String shortName;
  final bool isActive;
  final int productCount;

  const UnitEntity({
    required this.id,
    required this.name,
    required this.shortName,
    this.isActive = true,
    this.productCount = 0,
  });
}

/// A product with its current stock flattened in.
///
/// Prices are integer paisa (19900 = Rs. 199.00 — never floating-point);
/// taxRateBps is basis points (1300 = 13.00%).
class ProductEntity {
  final int id;
  final String name;
  final int? categoryId;
  final String? categoryName;
  final int? unitId;
  final String? unitShortName;
  final String? sku;
  final String? barcode;
  final String? description;
  final int costPrice;
  final int sellingPrice;
  final int? wholesalePrice;
  final int taxRateBps;
  final String? imageUrl;
  final bool isActive;
  final double stockQuantity;
  final double minQuantity;
  final bool isLowStock;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProductEntity({
    required this.id,
    required this.name,
    this.categoryId,
    this.categoryName,
    this.unitId,
    this.unitShortName,
    this.sku,
    this.barcode,
    this.description,
    this.costPrice = 0,
    this.sellingPrice = 0,
    this.wholesalePrice,
    this.taxRateBps = 0,
    this.imageUrl,
    this.isActive = true,
    this.stockQuantity = 0,
    this.minQuantity = 0,
    this.isLowStock = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Profit margin per unit in paisa (selling - cost). Negative = sold at loss.
  int get margin => sellingPrice - costPrice;

  /// Tax rate as a percentage display string: 1300 -> "13%".
  String get taxRateLabel =>
      '${(taxRateBps / 100).toStringAsFixed(taxRateBps % 100 == 0 ? 0 : 2)}%';
}

/// One page of products with pagination metadata (server shape).
class ProductPage {
  final List<ProductEntity> data;
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  const ProductPage({
    required this.data,
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  static const empty = ProductPage(
    data: [],
    page: 1,
    pageSize: 20,
    totalItems: 0,
    totalPages: 0,
    hasNext: false,
    hasPrev: false,
  );
}
