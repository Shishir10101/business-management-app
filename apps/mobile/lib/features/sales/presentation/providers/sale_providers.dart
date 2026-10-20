import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../inventory/presentation/providers/inventory_providers.dart';
import '../../../parties/presentation/providers/party_providers.dart';
import '../../data/repositories/sale_repository_impl.dart';
import '../../domain/entities/sale_entity.dart';

/// Current search text for the sale list.
final saleSearchProvider = StateProvider<String>((ref) => '');

/// Payment-status filter ('Paid' | 'Partial' | 'Unpaid'; null = all).
final saleStatusFilterProvider = StateProvider<String?>((ref) => null);

/// Sales of the active business, newest first.
final saleListProvider = FutureProvider<List<SaleEntity>>((ref) async {
  final page = await ref.read(saleRepositoryProvider).getSales(
        search: ref.watch(saleSearchProvider),
        paymentStatus: ref.watch(saleStatusFilterProvider),
        pageSize: 100,
      );
  return page.data;
});

/// The five most recent sales, for the home screen's activity feed.
///
/// Deliberately its own provider: the home screen must not pull the 100-row
/// list the sales tab keeps warm just to show five rows.
final recentSalesProvider = FutureProvider<List<SaleEntity>>((ref) async {
  final page = await ref
      .read(saleRepositoryProvider)
      .getSales(page: 1, pageSize: 5);
  return page.data;
});

/// Full sale by id (detail page).
final saleDetailProvider =
    FutureProvider.family<SaleEntity, int>((ref, id) async {
  return ref.read(saleRepositoryProvider).getSale(id);
});

/// Refreshes sales and everything a sale mutates: stock (inventory) and the
/// customer khata.
void refreshSales(WidgetRef ref) {
  ref.invalidate(saleListProvider);
  ref.invalidate(recentSalesProvider);
  ref.invalidate(saleDetailProvider);
  refreshInventory(ref);
  refreshParties(ref);
}
