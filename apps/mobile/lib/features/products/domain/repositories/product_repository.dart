import '../entities/product_entity.dart';

/// Product repository contract (domain layer): categories, units, products.
/// All operations are scoped to the user's active business on the server.
abstract class ProductRepository {
  // --- Categories ---
  Future<List<CategoryEntity>> getCategories();
  Future<CategoryEntity> createCategory({
    required String name,
    String? description,
    int? parentId,
  });
  Future<void> updateCategory(
    int id, {
    required String name,
    String? description,
    int? parentId,
    bool isActive = true,
  });
  Future<void> deleteCategory(int id);

  // --- Units ---
  Future<List<UnitEntity>> getUnits();
  Future<UnitEntity> createUnit(
      {required String name, required String shortName});
  Future<void> updateUnit(
    int id, {
    required String name,
    required String shortName,
    bool isActive = true,
  });
  Future<void> deleteUnit(int id);

  // --- Products ---
  Future<ProductPage> getProducts({
    String? search,
    int? categoryId,
    bool? isActive,
    int page = 1,
    int pageSize = 20,
  });

  Future<ProductEntity> getProduct(int id);

  Future<ProductEntity> createProduct({
    required String name,
    int? categoryId,
    int? unitId,
    String? sku,
    String? barcode,
    String? description,
    int costPrice = 0,
    int sellingPrice = 0,
    int? wholesalePrice,
    int taxRateBps = 0,
    String? imageUrl,
    bool isActive = true,
    double openingQuantity = 0,
    double minQuantity = 0,
  });

  Future<ProductEntity> updateProduct(
    int id, {
    required String name,
    int? categoryId,
    int? unitId,
    String? sku,
    String? barcode,
    String? description,
    int costPrice = 0,
    int sellingPrice = 0,
    int? wholesalePrice,
    int taxRateBps = 0,
    String? imageUrl,
    bool isActive = true,
    double minQuantity = 0,
  });

  Future<void> deleteProduct(int id);
}
