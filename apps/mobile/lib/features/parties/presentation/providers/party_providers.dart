import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../payments/presentation/providers/payment_providers.dart';
import '../../data/repositories/party_repository_impl.dart';
import '../../domain/entities/party_entity.dart';

/// Current search text for the customer list.
final customerSearchProvider = StateProvider<String>((ref) => '');

/// Current search text for the supplier list.
final supplierSearchProvider = StateProvider<String>((ref) => '');

/// True while the next page of the customer list is being fetched.
final customerLoadingMoreProvider = StateProvider<bool>((ref) => false);

/// True while the next page of the supplier list is being fetched.
final supplierLoadingMoreProvider = StateProvider<bool>((ref) => false);

/// Customers of the active business with their khata balances.
///
/// The first page loads on build; [loadMore] appends the next one. Before this
/// carried paging metadata the list silently stopped at the first page, hiding
/// every customer past the 50th.
class CustomerListNotifier
    extends AutoDisposeAsyncNotifier<PartyPage<CustomerEntity>> {
  static const int pageSize = 50;

  @override
  Future<PartyPage<CustomerEntity>> build() {
    return ref.watch(partyRepositoryProvider).getCustomers(
          search: ref.watch(customerSearchProvider),
          pageSize: pageSize,
        );
  }

  /// Appends the next page. No-op when the last page is already on screen.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasNext) return;

    final loading = ref.read(customerLoadingMoreProvider.notifier);
    if (loading.state) return;
    loading.state = true;
    try {
      final next = await ref.read(partyRepositoryProvider).getCustomers(
            search: ref.read(customerSearchProvider),
            page: current.page + 1,
            pageSize: current.pageSize,
          );

      // A rebuild (new search text) replaced the list while this page was in
      // flight — drop the stale page rather than mixing two queries.
      if (!identical(state.valueOrNull, current)) return;

      state = AsyncData(PartyPage<CustomerEntity>(
        items: [...current.items, ...next.items],
        page: next.page,
        pageSize: next.pageSize,
        totalItems: next.totalItems,
        hasNext: next.hasNext,
      ));
    } finally {
      loading.state = false;
    }
  }
}

final customerListProvider = AsyncNotifierProvider.autoDispose<
    CustomerListNotifier, PartyPage<CustomerEntity>>(CustomerListNotifier.new);

/// Full customer by id (edit form).
final customerDetailProvider =
    FutureProvider.family<CustomerEntity, int>((ref, id) async {
  return ref.read(partyRepositoryProvider).getCustomer(id);
});/// Suppliers of the active business with their khata balances.
class SupplierListNotifier
    extends AutoDisposeAsyncNotifier<PartyPage<SupplierEntity>> {
  static const int pageSize = 50;

  @override
  Future<PartyPage<SupplierEntity>> build() {
    return ref.watch(partyRepositoryProvider).getSuppliers(
          search: ref.watch(supplierSearchProvider),
          pageSize: pageSize,
        );
  }

  /// Appends the next page. No-op when the last page is already on screen.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasNext) return;

    final loading = ref.read(supplierLoadingMoreProvider.notifier);
    if (loading.state) return;
    loading.state = true;
    try {
      final next = await ref.read(partyRepositoryProvider).getSuppliers(
            search: ref.read(supplierSearchProvider),
            page: current.page + 1,
            pageSize: current.pageSize,
          );

      if (!identical(state.valueOrNull, current)) return;

      state = AsyncData(PartyPage<SupplierEntity>(
        items: [...current.items, ...next.items],
        page: next.page,
        pageSize: next.pageSize,
        totalItems: next.totalItems,
        hasNext: next.hasNext,
      ));
    } finally {
      loading.state = false;
    }
  }
}

final supplierListProvider = AsyncNotifierProvider.autoDispose<
    SupplierListNotifier, PartyPage<SupplierEntity>>(SupplierListNotifier.new);

/// Full supplier by id (edit form).
final supplierDetailProvider =
    FutureProvider.family<SupplierEntity, int>((ref, id) async {
  return ref.read(partyRepositoryProvider).getSupplier(id);
});

/// Ledger for a party. Args: (kind, partyId).
typedef PartyLedgerArgs = (PartyKind, int);final partyLedgerProvider =
    FutureProvider.family<PartyLedgerEntity, PartyLedgerArgs>((ref, args) {
  final (kind, partyId) = args;
  final repository = ref.read(partyRepositoryProvider);
  return kind == PartyKind.customer
      ? repository.getCustomerLedger(partyId)
      : repository.getSupplierLedger(partyId);
});

/// Rows per request when a picker loads a whole list.
const int _pickerPageSize = 100;

/// Pages a picker will load before giving up (1000 rows).
const int _pickerMaxPages = 10;

/// Every customer, for the forms' pickers.
///
/// The pickers filter on the device, so they need the whole list: reading one
/// page made every customer past the 50th unselectable in a sale or invoice.
/// Pages are fetched until the last one, capped so a huge catalog cannot stall
/// a form.
final customerPickerProvider =
    FutureProvider.autoDispose<List<CustomerEntity>>((ref) async {
  final repository = ref.watch(partyRepositoryProvider);
  final all = <CustomerEntity>[];
  for (var page = 1; page <= _pickerMaxPages; page++) {
    final result =
        await repository.getCustomers(page: page, pageSize: _pickerPageSize);
    all.addAll(result.items);
    if (!result.hasNext) break;
  }
  return all;
});

/// Every supplier, for the forms' pickers. See [customerPickerProvider].
final supplierPickerProvider =
    FutureProvider.autoDispose<List<SupplierEntity>>((ref) async {
  final repository = ref.watch(partyRepositoryProvider);
  final all = <SupplierEntity>[];
  for (var page = 1; page <= _pickerMaxPages; page++) {
    final result =
        await repository.getSuppliers(page: page, pageSize: _pickerPageSize);
    all.addAll(result.items);
    if (!result.hasNext) break;
  }
  return all;
});

/// Total receivable (what customers owe us) for the whole business.
///
/// Taken from the server-side payment summary, NOT summed over the customer
/// list: the list is paged, so summing it silently dropped every customer past
/// the first page from a number the shopkeeper reads as "money to collect".
final totalReceivableProvider = FutureProvider<int>((ref) async {
  final summary = await ref.watch(paymentSummaryProvider.future);
  return summary.totalReceivable;
});

/// Total payable (what we owe suppliers) for the whole business.
final totalPayableProvider = FutureProvider<int>((ref) async {
  final summary = await ref.watch(paymentSummaryProvider.future);
  return summary.totalPayable;
});

/// Refreshes party lists and ledgers after a mutation.
void refreshParties(WidgetRef ref) {
  ref.invalidate(customerListProvider);
  ref.invalidate(supplierListProvider);
  ref.invalidate(customerPickerProvider);
  ref.invalidate(supplierPickerProvider);
  ref.invalidate(totalReceivableProvider);
  ref.invalidate(totalPayableProvider);
  ref.invalidate(partyLedgerProvider);
  // Detail (edit form) providers are family-based; invalidating without an
  // argument invalidates every cached entry.
  ref.invalidate(customerDetailProvider);
  ref.invalidate(supplierDetailProvider);
}
