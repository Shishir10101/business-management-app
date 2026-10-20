import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';

/// Remote data source for the inventory API.
class InventoryRemoteDatasource {
  final Dio _dio;

  InventoryRemoteDatasource(this._dio);

  Future<Map<String, dynamic>> getInventory({
    String? search,
    bool lowStockOnly = false,
    String? sortBy,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get('/inventory', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      if (lowStockOnly) 'lowStockOnly': true,
      if (sortBy != null) 'sortBy': sortBy,
      'page': page,
      'pageSize': pageSize,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getLowStock() async {
    final response = await _dio.get('/inventory/low-stock');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> adjustStock(
    int productId, {
    required double quantity,
    String? notes,
  }) async {
    final response = await _dio.post('/inventory/$productId/adjust', data: {
      'quantity': quantity,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMovements(
    int productId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get(
      '/inventory/$productId/movements',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return response.data as Map<String, dynamic>;
  }
}

/// Provider for the inventory remote data source.
final inventoryRemoteDatasourceProvider =
    Provider<InventoryRemoteDatasource>((ref) {
  return InventoryRemoteDatasource(ref.read(dioProvider));
});
