/// User domain entity — pure business object, no serialization.
class UserEntity {
  final int id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String locale;
  final String timezone;
  final String? profileImageUrl;

  const UserEntity({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    required this.locale,
    required this.timezone,
    this.profileImageUrl,
  });
}

/// Business summary entity for the user's business memberships.
class BusinessEntity {
  final int id;
  final String name;
  final String role;

  const BusinessEntity({
    required this.id,
    required this.name,
    required this.role,
  });
}

/// Auth response entity.
class AuthResult {
  final UserEntity user;
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final List<BusinessEntity>? businesses;

  const AuthResult({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    this.businesses,
  });
}
