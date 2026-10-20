import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/format_utils.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../providers/inventory_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/router/nav.dart';

/// Inventory dashboard: stock levels, low-stock alerts and quick adjustment.
class InventoryDashboardPage extends ConsumerWidget {
  const InventoryDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final inventoryAsync = ref.watch(inventoryListProvider);
    final lowStockOnly = ref.watch(inventoryLowStockOnlyProvider);
    final sort = ref.watch(inventorySortProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.inventory),
        actions: [
          IconButton(
            tooltip: l10n.lowStockOnly,
            isSelected: lowStockOnly,
            icon: const Icon(Icons.warning_amber_outlined),
            onPressed: () => ref
                .read(inventoryLowStockOnlyProvider.notifier)
                .state = !lowStockOnly,
          ),
          PopupMenuButton<String>(
            tooltip: l10n.sort,
            initialValue: sort,
            onSelected: (value) =>
                ref.read(inventorySortProvider.notifier).state = value,
            itemBuilder: (context) => [
              PopupMenuItem(value: 'name', child: Text(l10n.sortByName)),
              PopupMenuItem(value: 'quantity', child: Text(l10n.sortByQuantity)),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.searchProducts,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              textInputAction: TextInputAction.search,
              onChanged: (value) =>
                  ref.read(inventorySearchProvider.notifier).state = value,
            ),
          ),
          Expanded(
            child: inventoryAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48),
                      const SizedBox(height: 12),
                      Text(l10n.couldNotLoad('$error'),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => ref.invalidate(inventoryListProvider),
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
              ),
              data: (page) {
                if (page.data.isEmpty) {
                  return Center(
                    child: Text(lowStockOnly
                        ? l10n.noLowStockProducts
                        : l10n.noProductsYet),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(inventoryListProvider),
                  child: ListView.builder(
                    itemCount: page.data.length,
                    itemBuilder: (context, index) =>
                        _StockTile(product: page.data[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StockTile extends StatelessWidget {
  final ProductEntity product;

  const _StockTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final quantityText = formatQuantity(product.stockQuantity);
    final unitText =
        product.unitShortName != null ? ' ${product.unitShortName}' : '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        title: Text(
          product.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          product.isLowStock
              ? l10n.lowAtOrBelow(
                  formatQuantity(product.minQuantity), unitText)
              : l10n.minimumIs(
                  formatQuantity(product.minQuantity), unitText),
        ),
        trailing: Chip(
          label: Text(l10n.quantityWithUnit(quantityText, unitText)),
          backgroundColor: product.isLowStock
              ? theme.colorScheme.errorContainer
              : theme.colorScheme.surfaceVariant,
        ),
        onTap: () => openRoute(context, '/inventory/${product.id}/adjust'),
      ),
    );
  }
}
