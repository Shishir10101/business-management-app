import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/user_entity.dart';

/// Remote data source for auth API calls.
class AuthRemoteDatasource {
  final Dio _dio;

  AuthRemoteDatasource(this._dio);

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
    String locale = 'ne',
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'fullName': fullName,
      'email': email,
      'password': password,
      'phoneNumber': phoneNumber,
      'locale': locale,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await _dio.post('/auth/refresh', data: {
      'refreshToken': refreshToken,
    });
    return response.data;
  }

  Future<void> logout(String? refreshToken) async {
    await _dio.post('/auth/logout', data: {
      if (refreshToken != null) 'refreshToken': refreshToken,
    });
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get('/auth/me');
    return response.data;
  }

  Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    String? phoneNumber,
    required String locale,
  }) async {
    final response = await _dio.put('/auth/profile', data: {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'locale': locale,
    });
    return response.data;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.post('/auth/change-password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }
}

/// Provider for the auth remote data source.
final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  return AuthRemoteDatasource(ref.read(dioProvider));
});

/// Maps JSON from API to domain entities.
class AuthMapper {
  static AuthResult fromAuthResponse(Map<String, dynamic> json) {
    final businesses = (json['businesses'] as List<dynamic>?)
        ?.map((b) => BusinessEntity(
              id: b['id'] as int,
              name: b['name'] as String,
              role: b['role'] as String,
            ))
        .toList();

    return AuthResult(
      user: UserEntity(
        id: json['userId'] as int,
        email: json['email'] as String,
        fullName: json['fullName'] as String,
        // The login response carries the account's saved locale; without it the
        // client used to default to Nepali for everyone.
        locale: json['locale'] as String? ?? 'en',
        timezone: 'Asia/Kathmandu',
      ),
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: json['expiresIn'] as int,
      businesses: businesses,
    );
  }

  static UserEntity fromProfileResponse(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'] as int,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      locale: json['locale'] as String,
      timezone: json['timezone'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }
}
