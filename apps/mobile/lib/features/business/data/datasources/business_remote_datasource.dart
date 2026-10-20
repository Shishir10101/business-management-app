import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';

/// Remote data source for business API calls.
class BusinessRemoteDatasource {
  final Dio _dio;

  BusinessRemoteDatasource(this._dio);

  Future<List<dynamic>> getMyBusinesses() async {
    final response = await _dio.get('/businesses');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createBusiness({
    required String name,
    String? type,
    String? panNumber,
    String? phoneNumber,
    String? email,
    String? addressLine,
    String? city,
    String? district,
    String? province,
    String? wardNumber,
    String currency = 'NPR',
  }) async {
    final response = await _dio.post('/businesses', data: {
      'name': name,
      if (type != null) 'type': type,
      if (panNumber != null) 'panNumber': panNumber,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (email != null) 'email': email,
      if (addressLine != null) 'addressLine': addressLine,
      if (city != null) 'city': city,
      if (district != null) 'district': district,
      if (province != null) 'province': province,
      if (wardNumber != null) 'wardNumber': wardNumber,
      'currency': currency,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getBusiness(int id) async {
    final response = await _dio.get('/businesses/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateBusiness(
    int id, {
    required String name,
    String? type,
    String? panNumber,
    String? phoneNumber,
    String? email,
    String? addressLine,
    String? city,
    String? district,
    String? province,
    String? wardNumber,
    String? logoUrl,
    String currency = 'NPR',
    bool isActive = true,
  }) async {
    final response = await _dio.put('/businesses/$id', data: {
      'name': name,
      if (type != null) 'type': type,
      if (panNumber != null) 'panNumber': panNumber,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (email != null) 'email': email,
      if (addressLine != null) 'addressLine': addressLine,
      if (city != null) 'city': city,
      if (district != null) 'district': district,
      if (province != null) 'province': province,
      if (wardNumber != null) 'wardNumber': wardNumber,
      if (logoUrl != null) 'logoUrl': logoUrl,
      'currency': currency,
      'isActive': isActive,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteBusiness(int id) async {
    await _dio.delete('/businesses/$id');
  }

  /// Switches active business. Response is an AuthResponse with new tokens.
  Future<Map<String, dynamic>> switchBusiness(int id) async {
    final response = await _dio.post('/businesses/$id/switch', data: {});
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getMembers(int id) async {
    final response = await _dio.get('/businesses/$id/members');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> inviteMember(
    int id, {
    required String email,
    required String role,
  }) async {
    final response = await _dio.post('/businesses/$id/members', data: {
      'email': email,
      'role': role,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateMemberRole(
    int id,
    int memberId, {
    required String role,
  }) async {
    final response = await _dio.put('/businesses/$id/members/$memberId', data: {
      'role': role,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<void> removeMember(int id, int memberId) async {
    await _dio.delete('/businesses/$id/members/$memberId');
  }
}

/// Provider for the business remote data source.
final businessRemoteDatasourceProvider =
    Provider<BusinessRemoteDatasource>((ref) {
  return BusinessRemoteDatasource(ref.read(dioProvider));
});
