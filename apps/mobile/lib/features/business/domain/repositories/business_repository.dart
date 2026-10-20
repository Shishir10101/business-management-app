import '../../../auth/domain/entities/user_entity.dart';
import '../entities/business_entity.dart';

/// Business repository contract (domain layer).
abstract class BusinessRepository {
  /// All businesses the current user belongs to.
  Future<List<BusinessEntity>> getMyBusinesses();

  /// Creates a business; the caller becomes its Owner.
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
  });

  Future<BusinessDetailEntity> getBusiness(int id);

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
  });

  Future<void> deleteBusiness(int id);

  /// Switches the active business; saves the rotated token pair locally.
  Future<AuthResult> switchBusiness(int id);

  Future<List<BusinessMemberEntity>> getMembers(int id);

  Future<BusinessMemberEntity> inviteMember(
    int id, {
    required String email,
    required String role,
  });

  Future<BusinessMemberEntity> updateMemberRole(
    int id,
    int memberId, {
    required String role,
  });

  Future<void> removeMember(int id, int memberId);
}
