import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../inventory/presentation/providers/inventory_providers.dart';
import '../../../parties/presentation/providers/party_providers.dart';
import '../../data/repositories/purchase_repository_impl.dart';
import '../../domain/entities/purchase_entity.dart';

/// Current search text for the purchase list.
final purchaseSearchProvider = StateProvider<String>((ref) => '');

/// Payment-status filter ('Paid' | 'Partial' | 'Unpaid'; null = all).
final purchaseStatusFilterProvider = StateProvider<String?>((ref) => null);

/// Purchases of the active business, newest first.
final purchaseListProvider = FutureProvider<List<PurchaseEntity>>((ref) async {
  final page = await ref.read(purchaseRepositoryProvider).getPurchases(
        search: ref.watch(purchaseSearchProvider),
        paymentStatus: ref.watch(purchaseStatusFilterProvider),
        pageSize: 100,
      );
  return page.data;
});

/// Full purchase by id (detail page).
final purchaseDetailProvider =
    FutureProvider.family<PurchaseEntity, int>((ref, id) async {
  return ref.read(purchaseRepositoryProvider).getPurchase(id);
});

/// Refreshes purchases and everything a purchase mutates: stock (inventory)
/// and the supplier khata.
void refreshPurchases(WidgetRef ref) {
  ref.invalidate(purchaseListProvider);
  ref.invalidate(purchaseDetailProvider);
  refreshInventory(ref);
  refreshParties(ref);
}
