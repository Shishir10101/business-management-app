import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/user_entity.dart';
import '../../data/repositories/business_repository_impl.dart';
import '../../domain/entities/business_entity.dart';

/// All businesses the current user belongs to.
final myBusinessesProvider = FutureProvider<List<BusinessEntity>>((ref) async {
  return ref.read(businessRepositoryProvider).getMyBusinesses();
});

/// The business the user is currently working in (selection persisted in-memory;
/// the authoritative source is the "bid" claim of the stored JWT).
final activeBusinessProvider = StateProvider<BusinessEntity?>((ref) => null);

/// Full business profile by id.
final businessDetailProvider =
    FutureProvider.family<BusinessDetailEntity, int>((ref, id) async {
  return ref.read(businessRepositoryProvider).getBusiness(id);
});

/// Staff members of a business.
final businessMembersProvider =
    FutureProvider.family<List<BusinessMemberEntity>, int>((ref, id) async {
  return ref.read(businessRepositoryProvider).getMembers(id);
});

/// System roles assignable when inviting/managing staff.
const kAssignableRoles = [
  'Owner',
  'Admin',
  'Manager',
  'Accountant',
  'SalesStaff',
  'InventoryStaff',
  'Viewer',
];
