import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/network/dio_client.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../data/datasources/business_remote_datasource.dart';
import '../../domain/entities/business_entity.dart';
import '../../domain/repositories/business_repository.dart';

/// Implementation of BusinessRepository: remote API + secure token storage
/// (switch persists the rotated token pair, same contract as login).
class BusinessRepositoryImpl implements BusinessRepository {
  final BusinessRemoteDatasource _remote;
  final FlutterSecureStorage _storage;

  BusinessRepositoryImpl(this._remote, this._storage);

  @override
  Future<List<BusinessEntity>> getMyBusinesses() async {
    final list = await _remote.getMyBusinesses();
    return list
        .map((b) => BusinessEntity(
              id: b['id'] as int,
              name: b['name'] as String,
              role: b['role'] as String,
            ))
        .toList();
  }

  @override
  Future<BusinessDetailEntity> createBusiness({
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
    final json = await _remote.createBusiness(
      name: name,
      type: type,
      panNumber: panNumber,
      phoneNumber: phoneNumber,
      email: email,
      addressLine: addressLine,
      city: city,
      district: district,
      province: province,
      wardNumber: wardNumber,
      currency: currency,
    );
    return _detailFromJson(json);
  }

  @override
  Future<BusinessDetailEntity> getBusiness(int id) async {
    return _detailFromJson(await _remote.getBusiness(id));
  }

  @override
  Future<BusinessDetailEntity> updateBusiness(
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
    final json = await _remote.updateBusiness(
      id,
      name: name,
      type: type,
      panNumber: panNumber,
      phoneNumber: phoneNumber,
      email: email,
      addressLine: addressLine,
      city: city,
      district: district,
      province: province,
      wardNumber: wardNumber,
      logoUrl: logoUrl,
      currency: currency,
      isActive: isActive,
    );
    return _detailFromJson(json);
  }

  @override
  Future<void> deleteBusiness(int id) => _remote.deleteBusiness(id);

  @override
  Future<AuthResult> switchBusiness(int id) async {
    final json = await _remote.switchBusiness(id);
    final result = _authResultFromJson(json);
    // Persist the rotated tokens; subsequent requests use the new business context.
    await _storage.write(key: 'access_token', value: result.accessToken);
    await _storage.write(key: 'refresh_token', value: result.refreshToken);
    return result;
  }

  @override
  Future<List<BusinessMemberEntity>> getMembers(int id) async {
    final list = await _remote.getMembers(id);
    return list.map(_memberFromJson).toList();
  }

  @override
  Future<BusinessMemberEntity> inviteMember(
    int id, {
    required String email,
    required String role,
  }) async {
    return _memberFromJson(
        await _remote.inviteMember(id, email: email, role: role));
  }

  @override
  Future<BusinessMemberEntity> updateMemberRole(
    int id,
    int memberId, {
    required String role,
  }) async {
    return _memberFromJson(
        await _remote.updateMemberRole(id, memberId, role: role));
  }

  @override
  Future<void> removeMember(int id, int memberId) =>
      _remote.removeMember(id, memberId);

  BusinessDetailEntity _detailFromJson(Map<String, dynamic> json) {
    return BusinessDetailEntity(
      id: json['id'] as int,
      name: json['name'] as String,
      type: json['type'] as String?,
      panNumber: json['panNumber'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      email: json['email'] as String?,
      addressLine: json['addressLine'] as String?,
      city: json['city'] as String?,
      district: json['district'] as String?,
      province: json['province'] as String?,
      wardNumber: json['wardNumber'] as String?,
      logoUrl: json['logoUrl'] as String?,
      currency: json['currency'] as String? ?? 'NPR',
      isActive: json['isActive'] as bool? ?? true,
      role: json['role'] as String,
    );
  }

  BusinessMemberEntity _memberFromJson(dynamic json) {
    return BusinessMemberEntity(
      id: json['id'] as int,
      userId: json['userId'] as int,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      role: json['role'] as String,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  AuthResult _authResultFromJson(Map<String, dynamic> json) {
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
        locale: 'ne',
        timezone: 'Asia/Kathmandu',
      ),
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: json['expiresIn'] as int,
      businesses: businesses,
    );
  }
}

/// Provider for the business repository implementation.
final businessRepositoryProvider = Provider<BusinessRepository>((ref) {
  return BusinessRepositoryImpl(
    ref.read(businessRemoteDatasourceProvider),
    ref.read(secureStorageProvider),
  );
});
