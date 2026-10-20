import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../parties/presentation/providers/party_providers.dart';
import '../../../purchases/presentation/providers/purchase_providers.dart';
import '../../../sales/presentation/providers/sale_providers.dart';
import '../../data/repositories/payment_repository_impl.dart';
import '../../domain/entities/payment_entity.dart';

/// Current search text for the payment list.
final paymentSearchProvider = StateProvider<String>((ref) => '');

/// Payments of the active business, newest first.
final paymentListProvider = FutureProvider<List<PaymentEntity>>((ref) async {
  final page = await ref.read(paymentRepositoryProvider).getPayments(
        search: ref.watch(paymentSearchProvider),
        pageSize: 100,
      );
  return page.data;
});

/// Receivable/payable snapshot shown at the top of the payment list.
final paymentSummaryProvider =
    FutureProvider<ReceivablePayableSummary>((ref) async {
  return ref.read(paymentRepositoryProvider).getSummary();
});

/// Payment methods of the active business (plain list, not paged).
final paymentMethodsProvider =
    FutureProvider<List<PaymentMethodEntity>>((ref) async {
  return ref.read(paymentRepositoryProvider).getMethods();
});

/// Refreshes payments plus everything a payment changes: khata balances and
/// the sale/purchase documents whose due may have moved.
void refreshPayments(WidgetRef ref) {
  ref.invalidate(paymentListProvider);
  ref.invalidate(paymentSummaryProvider);
  ref.invalidate(paymentMethodsProvider);
  refreshParties(ref);
  ref.invalidate(saleListProvider);
  ref.invalidate(saleDetailProvider);
  ref.invalidate(purchaseListProvider);
  ref.invalidate(purchaseDetailProvider);
}
