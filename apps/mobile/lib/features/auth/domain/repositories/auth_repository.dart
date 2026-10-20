import '../../domain/entities/user_entity.dart';

/// Auth repository contract (domain layer).
abstract class AuthRepository {
  Future<AuthResult> register({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
    String locale = 'ne',
  });

  Future<AuthResult> login({
    required String email,
    required String password,
  });

  Future<AuthResult> refreshToken(String refreshToken);

  Future<void> logout(String? refreshToken);

  Future<UserEntity> getProfile();

  Future<UserEntity> updateProfile({
    required String fullName,
    String? phoneNumber,
    required String locale,
  });

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> saveTokens(String accessToken, String refreshToken);

  Future<void> clearTokens();

  Future<bool> hasTokens();
}
