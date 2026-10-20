import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/format_utils.dart';
import '../../../../core/widgets/cached_data_note.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/khata_snackbars.dart';
import '../../../../core/widgets/load_more_footer.dart';
import '../../domain/entities/product_entity.dart';
import '../providers/product_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/router/nav.dart';

/// Product catalog: searchable list with stock levels, low-stock badges,
/// category filter and quick links to category/unit management.
class ProductListPage extends ConsumerWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final productsAsync = ref.watch(productListProvider);
    final search = ref.watch(productSearchProvider);
    final categoryFilter = ref.watch(productCategoryFilterProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.products),
        actions: [
          IconButton(
            tooltip: l10n.categories,
            onPressed: () => openRoute(context, '/products/categories'),
            icon: const Icon(Icons.category_outlined),
          ),
          IconButton(
            tooltip: l10n.units,
            onPressed: () => openRoute(context, '/products/units'),
            icon: const Icon(Icons.straighten_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.searchNameSkuBarcode,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              textInputAction: TextInputAction.search,
              onChanged: (value) =>
                  ref.read(productSearchProvider.notifier).state = value,
            ),
          ),
          const CachedDataNote(group: 'products'),
          if (categories.isNotEmpty)
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(l10n.all),
                      selected: categoryFilter == null,
                      onSelected: (_) => ref
                          .read(productCategoryFilterProvider.notifier)
                          .state = null,
                    ),
                  ),
                  ...categories.map((category) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category.name),
                          selected: categoryFilter == category.id,
                          onSelected: (_) => ref
                                  .read(productCategoryFilterProvider.notifier)
                                  .state =
                              categoryFilter == category.id
                                  ? null
                                  : category.id,
                        ),
                      )),
                ],
              ),
            ),
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorState(
                message: l10n.couldNotLoad('$error'),
                onRetry: () => ref.invalidate(productListProvider),
              ),
              data: (page) {
                if (page.data.isEmpty) {
                  return _EmptyState(searching: search.isNotEmpty);
                }
                final loadingMore = ref.watch(productLoadingMoreProvider);
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(productListProvider),
                  child: ListView.builder(
                    // Clear of the extended FAB, which otherwise covers the last row.
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: page.data.length + (page.hasNext ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= page.data.length) {
                        return LoadMoreFooter(
                          loading: loadingMore,
                          remaining: page.totalItems - page.data.length,
                          onPressed: () => _loadMore(context, ref),
                        );
                      }
                      return _ProductTile(product: page.data[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openRoute(context, '/products/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.addProduct),
      ),
    );
  }

  /// Fetches the next page and appends it to the list.
  Future<void> _loadMore(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(productListProvider.notifier).loadMore();
    } catch (error) {
      if (context.mounted) showErrorSnackBar(context, '$error');
    }
  }
}

class _ProductTile extends ConsumerWidget {
  final ProductEntity product;

  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          [
            if (product.sku != null) product.sku!,
            formatPaisa(product.sellingPrice),
            if (product.categoryName != null) product.categoryName!,
          ].join('  •  '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$quantityText$unitText',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: product.isLowStock ? theme.colorScheme.error : null,
                  ),
                ),
                if (product.isLowStock)
                  Text(
                    l10n.lowStockAlert,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
              ],
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => openRoute(context, '/products/${product.id}/edit'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool searching;

  const _EmptyState({required this.searching});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (searching) {
      return EmptyState(
        icon: Icons.search_off,
        message: l10n.noProductsMatchSearch,
      );
    }
    return EmptyState(
      icon: Icons.inventory_2_outlined,
      message: l10n.noProductsYetAddFirst,
      actionLabel: l10n.addProduct,
      onAction: () => openRoute(context, '/products/new'),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(
              l10n.couldNotLoadProducts('$message'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: Text(l10n.retry)),
          ],
        ),
      ),
    );
  }
}
