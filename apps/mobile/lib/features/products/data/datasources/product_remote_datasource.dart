import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/offline/offline_providers.dart';
import '../../../../core/offline/offline_queue.dart';

/// Remote data source for the product catalog API.
/// All paths are relative to ApiConfig.apiBase (…/api).
///
/// Product writes go through an [OfflineQueue] (products are part of the sync
/// push protocol). Categories and units are not — the server has no offline
/// operation for them, so they stay online-only.
class ProductRemoteDatasource {
  final Dio _dio;
  final OfflineQueue _queue;

  ProductRemoteDatasource(this._dio, {OfflineQueue? queue})
      : _queue = queue ?? OfflineQueue.disabled();

  // --- Categories ---

  Future<List<dynamic>> getCategories() async {
    final response = await _dio.get('/categories');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createCategory({
    required String name,
    String? description,
    int? parentId,
  }) async {
    final response = await _dio.post('/categories', data: {
      'name': name,
      if (description != null) 'description': description,
      if (parentId != null) 'parentId': parentId,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<void> updateCategory(
    int id, {
    required String name,
    String? description,
    int? parentId,
    bool isActive = true,
  }) async {
    await _dio.put('/categories/$id', data: {
      'name': name,
      if (description != null) 'description': description,
      if (parentId != null) 'parentId': parentId,
      'isActive': isActive,
    });
  }

  Future<void> deleteCategory(int id) => _dio.delete('/categories/$id');

  // --- Units ---

  Future<List<dynamic>> getUnits() async {
    final response = await _dio.get('/units');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createUnit({
    required String name,
    required String shortName,
  }) async {
    final response = await _dio.post('/units', data: {
      'name': name,
      'shortName': shortName,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<void> updateUnit(
    int id, {
    required String name,
    required String shortName,
    bool isActive = true,
  }) async {
    await _dio.put('/units/$id', data: {
      'name': name,
      'shortName': shortName,
      'isActive': isActive,
    });
  }

  Future<void> deleteUnit(int id) => _dio.delete('/units/$id');

  // --- Products ---

  Future<Map<String, dynamic>> getProducts({
    String? search,
    int? categoryId,
    bool? isActive,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get('/products', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoryId != null) 'categoryId': categoryId,
      if (isActive != null) 'isActive': isActive,
      'page': page,
      'pageSize': pageSize,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getProduct(int id) async {
    final response = await _dio.get('/products/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createProduct({
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
    final body = _productBody(
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
      includeOpeningQuantity: true,
    );
    final result = await _queue.create(
      entityType: 'product',
      body: body,
      send: () async =>
          (await _dio.post('/products', data: body)).data as Map<String, dynamic>,
    );
    return result.value!;
  }

  Future<Map<String, dynamic>> updateProduct(
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
    final body = _productBody(
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
    final result = await _queue.update(
      entityType: 'product',
      entityId: id,
      body: body,
      send: () async =>
          (await _dio.put('/products/$id', data: body)).data as Map<String, dynamic>,
    );
    return result.value!;
  }

  Future<void> deleteProduct(int id) async {
    await _queue.remove(
      entityType: 'product',
      entityId: id,
      send: () async {
        await _dio.delete('/products/$id');
      },
    );
  }

  /// Shared create/update body, so the queued copy and the online copy can
  /// never disagree about which fields a product has.
  static Map<String, dynamic> _productBody({
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
    bool includeOpeningQuantity = false,
  }) {
    return {
      'name': name,
      'categoryId': categoryId,
      'unitId': unitId,
      'sku': sku,
      'barcode': barcode,
      'description': description,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'wholesalePrice': wholesalePrice,
      'taxRateBps': taxRateBps,
      'imageUrl': imageUrl,
      'isActive': isActive,
      // Only a create carries an opening stock movement; an update leaves
      // quantity alone (stock is adjusted through the inventory screens).
      if (includeOpeningQuantity) 'openingQuantity': openingQuantity,
      'minQuantity': minQuantity,
    };
  }
}

/// Provider for the product remote data source.
final productRemoteDatasourceProvider =
    Provider<ProductRemoteDatasource>((ref) {
  return ProductRemoteDatasource(
    ref.read(dioProvider),
    queue: ref.read(offlineQueueProvider),
  );
});
