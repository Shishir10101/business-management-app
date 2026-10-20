import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

/// Implementation of AuthRepository that coordinates remote API + secure storage.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _remote;
  final FlutterSecureStorage _storage;

  AuthRepositoryImpl(this._remote, this._storage);

  @override
  Future<AuthResult> register({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
    String locale = 'ne',
  }) async {
    final json = await _remote.register(
      fullName: fullName,
      email: email,
      password: password,
      phoneNumber: phoneNumber,
      locale: locale,
    );
    final result = AuthMapper.fromAuthResponse(json);
    await saveTokens(result.accessToken, result.refreshToken);
    return result;
  }

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final json = await _remote.login(email: email, password: password);
    final result = AuthMapper.fromAuthResponse(json);
    await saveTokens(result.accessToken, result.refreshToken);
    return result;
  }

  @override
  Future<AuthResult> refreshToken(String refreshToken) async {
    final json = await _remote.refreshToken(refreshToken);
    final result = AuthMapper.fromAuthResponse(json);
    await saveTokens(result.accessToken, result.refreshToken);
    return result;
  }

  @override
  Future<void> logout(String? refreshToken) async {
    try {
      await _remote.logout(refreshToken);
    } finally {
      await clearTokens();
    }
  }

  @override
  Future<UserEntity> getProfile() async {
    final json = await _remote.getProfile();
    return AuthMapper.fromProfileResponse(json);
  }

  @override
  Future<UserEntity> updateProfile({
    required String fullName,
    String? phoneNumber,
    required String locale,
  }) async {
    final json = await _remote.updateProfile(
      fullName: fullName,
      phoneNumber: phoneNumber,
      locale: locale,
    );
    return AuthMapper.fromProfileResponse(json);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _remote.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  @override
  Future<void> clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  @override
  Future<bool> hasTokens() async {
    final access = await _storage.read(key: 'access_token');
    return access != null;
  }
}

/// Provider for the auth repository implementation.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.read(authRemoteDatasourceProvider),
    ref.read(secureStorageProvider),
  );
});
