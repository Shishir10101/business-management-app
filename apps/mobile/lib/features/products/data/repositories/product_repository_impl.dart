import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/offline/cached_reader.dart';
import '../../../../core/offline/offline_providers.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_datasource.dart';

/// Implementation of ProductRepository against the Khata API.
///
/// Read methods go through an optional [CachedReader]: the answer is saved, and
/// when the network is down the saved copy is returned instead of an error. The
/// catalog and its categories/units are exactly what a shop needs to keep
/// looking things up offline.
class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDatasource _remote;
  final CachedReader? _reader;

  ProductRepositoryImpl(this._remote, {CachedReader? reader}) : _reader = reader;

  /// Runs a read through the cache when one is wired, or straight to the API.
  Future<T> _read<T>(String key, Future<T> Function() fetch) {
    final reader = _reader;
    if (reader == null) return fetch();
    return reader.read<T>(group: 'products', key: key, fetch: fetch);
  }

  @override
  Future<List<CategoryEntity>> getCategories() async {
    final list = await _read('categories', _remote.getCategories);
    return list.map(_categoryFromJson).toList();
  }

  @override
  Future<CategoryEntity> createCategory({
    required String name,
    String? description,
    int? parentId,
  }) async {
    final json = await _remote.createCategory(
      name: name,
      description: description,
      parentId: parentId,
    );
    return _categoryFromJson(json);
  }

  @override
  Future<void> updateCategory(
    int id, {
    required String name,
    String? description,
    int? parentId,
    bool isActive = true,
  }) =>
      _remote.updateCategory(
        id,
        name: name,
        description: description,
        parentId: parentId,
        isActive: isActive,
      );

  @override
  Future<void> deleteCategory(int id) => _remote.deleteCategory(id);

  @override
  Future<List<UnitEntity>> getUnits() async {
    final list = await _read('units', _remote.getUnits);
    return list.map(_unitFromJson).toList();
  }

  @override
  Future<UnitEntity> createUnit({
    required String name,
    required String shortName,
  }) async {
    final json = await _remote.createUnit(name: name, shortName: shortName);
    return _unitFromJson(json);
  }

  @override
  Future<void> updateUnit(
    int id, {
    required String name,
    required String shortName,
    bool isActive = true,
  }) =>
      _remote.updateUnit(
        id,
        name: name,
        shortName: shortName,
        isActive: isActive,
      );

  @override
  Future<void> deleteUnit(int id) => _remote.deleteUnit(id);

  @override
  Future<ProductPage> getProducts({
    String? search,
    int? categoryId,
    bool? isActive,
    int page = 1,
    int pageSize = 20,
  }) async {
    final json = await _read(
      'list:${search ?? ''}:${categoryId ?? ''}:${isActive ?? ''}:$page:$pageSize',
      () => _remote.getProducts(
        search: search,
        categoryId: categoryId,
        isActive: isActive,
        page: page,
        pageSize: pageSize,
      ),
    );
    return _productPageFromJson(json);
  }

  @override
  Future<ProductEntity> getProduct(int id) async {
    final json = await _remote.getProduct(id);
    return _productFromJson(json);
  }

  @override
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
  }) async {
    final json = await _remote.createProduct(
      name: name,
      categoryId: categoryId,
      unitId: unitId,
      sku: sku,
      barcode: barcode,
      description: description,
      costPrice: costPrice,
      sellingPrice: sellingPrice,
      wholesalePrice: wholesalePrice,
      taxRateBps: taxRateBps,
      imageUrl: imageUrl,
      isActive: isActive,
      openingQuantity: openingQuantity,
      minQuantity: minQuantity,
    );
    return _productFromJson(json);
  }

  @override
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
  }) async {
    final json = await _remote.updateProduct(
      id,
      name: name,
      categoryId: categoryId,
      unitId: unitId,
      sku: sku,
      barcode: barcode,
      description: description,
      costPrice: costPrice,
      sellingPrice: sellingPrice,
      wholesalePrice: wholesalePrice,
      taxRateBps: taxRateBps,
      imageUrl: imageUrl,
      isActive: isActive,
      minQuantity: minQuantity,
    );
    return _productFromJson(json);
  }

  @override
  Future<void> deleteProduct(int id) => _remote.deleteProduct(id);

  // --- mapping ---

  CategoryEntity _categoryFromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    return CategoryEntity(
      id: map['id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
      parentId: map['parentId'] as int?,
      parentName: map['parentName'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      productCount: map['productCount'] as int? ?? 0,
    );
  }

  UnitEntity _unitFromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    return UnitEntity(
      id: map['id'] as int,
      name: map['name'] as String,
      shortName: map['shortName'] as String,
      isActive: map['isActive'] as bool? ?? true,
      productCount: map['productCount'] as int? ?? 0,
    );
  }

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

/// Provider for the product repository implementation.
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepositoryImpl(
    ref.read(productRemoteDatasourceProvider),
    reader: cachedReaderFor(ref),
  );
});
