import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/product_repository_impl.dart';
import '../../domain/entities/product_entity.dart';

/// Current search text for the product list.
final productSearchProvider = StateProvider<String>((ref) => '');

/// Category filter for the product list (null = all categories).
final productCategoryFilterProvider = StateProvider<int?>((ref) => null);

/// True while the next page of products is being fetched.
final productLoadingMoreProvider = StateProvider<bool>((ref) => false);

/// Paged product list. The first page loads on build; [loadMore] appends.
///
/// The list used to request 100 rows and stop, so a catalog bigger than that
/// (which the CSV import now makes easy) was silently cut off. The page size is
/// smaller and the rest is reachable through [loadMore].
class ProductListNotifier extends AutoDisposeAsyncNotifier<ProductPage> {
  /// Small enough for a fast first paint; the API caps a page at 100.
  static const int pageSize = 50;

  @override
  Future<ProductPage> build() {
    final repository = ref.watch(productRepositoryProvider);
    return repository.getProducts(
      search: ref.watch(productSearchProvider),
      categoryId: ref.watch(productCategoryFilterProvider),
      pageSize: pageSize,
    );
  }

  /// Appends the next page. No-op when the last page is already on screen.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasNext) return;

    final loading = ref.read(productLoadingMoreProvider.notifier);
    if (loading.state) return;
    loading.state = true;
    try {
      final next = await ref.read(productRepositoryProvider).getProducts(
            search: ref.read(productSearchProvider),
            categoryId: ref.read(productCategoryFilterProvider),
            page: current.page + 1,
            pageSize: current.pageSize,
          );

      // A rebuild (new search text or filter) replaced the list while this page
      // was in flight — drop it rather than mixing two queries.
      if (!identical(state.valueOrNull, current)) return;

      state = AsyncData(ProductPage(
        data: [...current.data, ...next.data],
        page: next.page,
        pageSize: next.pageSize,
        totalItems: next.totalItems,
        totalPages: next.totalPages,
        hasNext: next.hasNext,
        hasPrev: next.hasPrev,
      ));
    } finally {
      loading.state = false;
    }
  }
}

final productListProvider =
    AsyncNotifierProvider.autoDispose<ProductListNotifier, ProductPage>(
  ProductListNotifier.new,
);

/// All categories of the active business.
final categoriesProvider = FutureProvider<List<CategoryEntity>>((ref) async {
  return ref.read(productRepositoryProvider).getCategories();
});

/// All units of the active business.
final unitsProvider = FutureProvider<List<UnitEntity>>((ref) async {
  return ref.read(productRepositoryProvider).getUnits();
});

/// Full product by id (for the edit form).
final productDetailProvider =
    FutureProvider.family<ProductEntity, int>((ref, id) async {
  return ref.read(productRepositoryProvider).getProduct(id);
});

/// Rows per request when the sale/purchase picker loads the catalog.
const int _pickerPageSize = 100;

/// Pages the picker will load before giving up (1000 products).
const int _pickerMaxPages = 10;

/// The whole catalog, for the forms' product picker.
///
/// The picker filters on the device, so it needs more than one page: with a
/// single page every product past it was unselectable in a sale. Pages are
/// fetched until the last one, capped so a huge catalog cannot stall a form.
final productPickerProvider =
    FutureProvider.autoDispose<List<ProductEntity>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  final all = <ProductEntity>[];
  for (var page = 1; page <= _pickerMaxPages; page++) {
    final result = await repository.getProducts(
      page: page,
      pageSize: _pickerPageSize,
    );
    all.addAll(result.data);
    if (!result.hasNext) break;
  }
  return all;
});

/// Refreshes every provider that depends on the catalog after a mutation.
void refreshCatalog(WidgetRef ref) {
  ref.invalidate(productListProvider);
  ref.invalidate(productPickerProvider);
  ref.invalidate(categoriesProvider);
  ref.invalidate(unitsProvider);
}
