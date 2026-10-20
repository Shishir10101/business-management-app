import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../products/domain/entities/product_entity.dart';
import '../../../products/presentation/providers/product_providers.dart';
import '../../data/repositories/inventory_repository_impl.dart';
import '../../domain/entities/stock_entity.dart';

/// Current search text for the inventory list.
final inventorySearchProvider = StateProvider<String>((ref) => '');

/// When true, the inventory list shows only low-stock products.
final inventoryLowStockOnlyProvider = StateProvider<bool>((ref) => false);

/// Stock sort: "name" (default) or "quantity".
final inventorySortProvider = StateProvider<String>((ref) => 'name');

/// Paged stock list. Rebuilds when search/low-stock/sort change.
final inventoryListProvider = FutureProvider<ProductPage>((ref) async {
  final repository = ref.read(inventoryRepositoryProvider);
  return repository.getInventory(
    search: ref.watch(inventorySearchProvider),
    lowStockOnly: ref.watch(inventoryLowStockOnlyProvider),
    sortBy: ref.watch(inventorySortProvider),
    pageSize: 100,
  );
});

/// All products at or below their minimum quantity.
final lowStockProvider = FutureProvider<List<ProductEntity>>((ref) async {
  return ref.read(inventoryRepositoryProvider).getLowStock();
});

/// Low-stock item count for the dashboard badge / home page.
final lowStockCountProvider = FutureProvider<int>((ref) async {
  final items = await ref.watch(lowStockProvider.future);
  return items.length;
});

/// Movement history for a product (family by product id), newest first.
final stockMovementsProvider =
    FutureProvider.family<MovementPage, int>((ref, productId) async {
  return ref.read(inventoryRepositoryProvider).getMovements(productId);
});

/// Refreshes every provider that depends on stock after an adjustment.
void refreshInventory(WidgetRef ref) {
  ref.invalidate(inventoryListProvider);
  ref.invalidate(lowStockProvider);
  ref.invalidate(lowStockCountProvider);
  ref.invalidate(stockMovementsProvider);
  refreshCatalog(ref);
}
