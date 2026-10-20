/// Business domain entities — pure business objects, no serialization.

/// Full business profile (role is the CALLER's role in this business).
class BusinessDetailEntity {
  final int id;
  final String name;
  final String? type;
  final String? panNumber;
  final String? phoneNumber;
  final String? email;
  final String? addressLine;
  final String? city;
  final String? district;
  final String? province;
  final String? wardNumber;
  final String? logoUrl;
  final String currency;
  final bool isActive;
  final String role;

  const BusinessDetailEntity({
    required this.id,
    required this.name,
    this.type,
    this.panNumber,
    this.phoneNumber,
    this.email,
    this.addressLine,
    this.city,
    this.district,
    this.province,
    this.wardNumber,
    this.logoUrl,
    required this.currency,
    required this.isActive,
    required this.role,
  });

  bool get isManager => role == 'Owner' || role == 'Admin';
}

/// Business staff member (a membership row with user info).
class BusinessMemberEntity {
  final int id;
  final int userId;
  final String email;
  final String fullName;
  final String role;
  final bool isActive;

  const BusinessMemberEntity({
    required this.id,
    required this.userId,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
  });
}
