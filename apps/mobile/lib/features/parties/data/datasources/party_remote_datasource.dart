import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/offline/offline_providers.dart';
import '../../../../core/offline/offline_queue.dart';

/// Remote data source for the party (customer/supplier) and ledger APIs.
///
/// Writes go through an [OfflineQueue]: when the device has no connection the
/// exact body the API would have received is queued for the next sync, and an
/// optimistic record (negative id) is returned so the form can close.
class PartyRemoteDatasource {
  final Dio _dio;
  final OfflineQueue _queue;

  PartyRemoteDatasource(this._dio, {OfflineQueue? queue})
      : _queue = queue ?? OfflineQueue.disabled();

  // --- Customers ---

  Future<Map<String, dynamic>> getCustomers({
    String? search,
    int page = 1,
    int pageSize = 50,
  }) async {
    final response = await _dio.get('/customers', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      'page': page,
      'pageSize': pageSize,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getCustomer(int id) async {
    final response = await _dio.get('/customers/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createCustomer({
    required String name,
    String? phoneNumber,
    String? email,
    String? addressLine,
    String? city,
    String? district,
    int openingBalance = 0,
    String? panNumber,
    int? creditLimit,
    String? notes,
    bool isActive = true,
  }) async {
    final body = _partyBody(
      name: name,
      phoneNumber: phoneNumber,
      email: email,
      addressLine: addressLine,
      city: city,
      district: district,
      openingBalance: openingBalance,
      panNumber: panNumber,
      creditLimit: creditLimit,
      notes: notes,
      isActive: isActive,
    );
    final result = await _queue.create(
      entityType: 'customer',
      body: body,
      send: () async =>
          (await _dio.post('/customers', data: body)).data as Map<String, dynamic>,
    );
    return result.value!;
  }

  Future<Map<String, dynamic>> updateCustomer(
    int id, {
    required String name,
    String? phoneNumber,
    String? email,
    String? addressLine,
    String? city,
    String? district,
    int openingBalance = 0,
    String? panNumber,
    int? creditLimit,
    String? notes,
    bool isActive = true,
  }) async {
    final body = _partyBody(
      name: name,
      phoneNumber: phoneNumber,
      email: email,
      addressLine: addressLine,
      city: city,
      district: district,
      openingBalance: openingBalance,
      panNumber: panNumber,
      creditLimit: creditLimit,
      notes: notes,
      isActive: isActive,
    );
    final result = await _queue.update(
      entityType: 'customer',
      entityId: id,
      body: body,
      send: () async =>
          (await _dio.put('/customers/$id', data: body)).data as Map<String, dynamic>,
    );
    return result.value!;
  }

  Future<void> deleteCustomer(int id) async {
    await _queue.remove(
      entityType: 'customer',
      entityId: id,
      send: () async {
        await _dio.delete('/customers/$id');
      },
    );
  }

  /// The create/update body. Shared so the queued copy and the online copy can
  /// never disagree about which fields a party has.
  static Map<String, dynamic> _partyBody({
    required String name,
    String? phoneNumber,
    String? email,
    String? addressLine,
    String? city,
    String? district,
    int openingBalance = 0,
    String? panNumber,
    int? creditLimit,
    String? notes,
    bool isActive = true,
  }) {
    return {
      'name': name,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (email != null) 'email': email,
      if (addressLine != null) 'addressLine': addressLine,
      if (city != null) 'city': city,
      if (district != null) 'district': district,
      'openingBalance': openingBalance,
      if (panNumber != null) 'panNumber': panNumber,
      if (creditLimit != null) 'creditLimit': creditLimit,
      if (notes != null) 'notes': notes,
      'isActive': isActive,
    };
  }

  Future<Map<String, dynamic>> getCustomerLedger(int id) async {
    final response = await _dio.get('/customers/$id/ledger',
        queryParameters: {'page': 1, 'pageSize': 100});
    return response.data as Map<String, dynamic>;
  }

  // --- Suppliers ---

  Future<Map<String, dynamic>> getSuppliers({
    String? search,
    int page = 1,
    int pageSize = 50,
  }) async {
    final response = await _dio.get('/suppliers', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      'page': page,
      'pageSize': pageSize,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSupplier(int id) async {
    final response = await _dio.get('/suppliers/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createSupplier({
    required String name,
    String? phoneNumber,
    String? email,
    String? addressLine,
    String? city,
    String? district,
    int openingBalance = 0,
    String? panNumber,
    String? notes,
    bool isActive = true,
  }) async {
    final body = _partyBody(
      name: name,
      phoneNumber: phoneNumber,
      email: email,
      addressLine: addressLine,
      city: city,
      district: district,
      openingBalance: openingBalance,
      panNumber: panNumber,
      notes: notes,
      isActive: isActive,
    );
    final result = await _queue.create(
      entityType: 'supplier',
      body: body,
      send: () async =>
          (await _dio.post('/suppliers', data: body)).data as Map<String, dynamic>,
    );
    return result.value!;
  }

  Future<Map<String, dynamic>> updateSupplier(
    int id, {
    required String name,
    String? phoneNumber,
    String? email,
    String? addressLine,
    String? city,
    String? district,
    int openingBalance = 0,
    String? panNumber,
    String? notes,
    bool isActive = true,
  }) async {
    final body = _partyBody(
      name: name,
      phoneNumber: phoneNumber,
      email: email,
      addressLine: addressLine,
      city: city,
      district: district,
      openingBalance: openingBalance,
      panNumber: panNumber,
      notes: notes,
      isActive: isActive,
    );
    final result = await _queue.update(
      entityType: 'supplier',
      entityId: id,
      body: body,
      send: () async =>
          (await _dio.put('/suppliers/$id', data: body)).data as Map<String, dynamic>,
    );
    return result.value!;
  }

  Future<void> deleteSupplier(int id) async {
    await _queue.remove(
      entityType: 'supplier',
      entityId: id,
      send: () async {
        await _dio.delete('/suppliers/$id');
      },
    );
  }

  Future<Map<String, dynamic>> getSupplierLedger(int id) async {
    final response = await _dio.get('/suppliers/$id/ledger',
        queryParameters: {'page': 1, 'pageSize': 100});
    return response.data as Map<String, dynamic>;
  }
}

/// Provider for the party remote data source.
final partyRemoteDatasourceProvider = Provider<PartyRemoteDatasource>((ref) {
  return PartyRemoteDatasource(
    ref.read(dioProvider),
    queue: ref.read(offlineQueueProvider),
  );
});
