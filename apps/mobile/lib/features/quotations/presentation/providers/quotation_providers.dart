import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../parties/presentation/providers/party_providers.dart';
import '../../../sales/presentation/providers/sale_providers.dart';
import '../../data/repositories/quotation_repository_impl.dart';
import '../../domain/entities/quotation_entity.dart';

/// Current search text for the quotation list.
final quotationSearchProvider = StateProvider<String>((ref) => '');

/// Status filter ('Draft' | 'Sent' | 'Accepted' | 'Rejected' | 'Expired';
/// null = all).
final quotationStatusFilterProvider = StateProvider<String?>((ref) => null);

/// Quotations of the active business, newest first.
final quotationListProvider =
    FutureProvider<List<QuotationEntity>>((ref) async {
  final page = await ref.read(quotationRepositoryProvider).getQuotations(
        search: ref.watch(quotationSearchProvider),
        status: ref.watch(quotationStatusFilterProvider),
        pageSize: 100,
      );
  return page.data;
});

/// Full quotation by id (detail page).
final quotationDetailProvider =
    FutureProvider.family<QuotationEntity, int>((ref, id) async {
  return ref.read(quotationRepositoryProvider).getQuotation(id);
});

/// Refreshes quotations plus everything a conversion mutates: the sale it
/// created and the customer khata.
void refreshQuotations(WidgetRef ref) {
  ref.invalidate(quotationListProvider);
  ref.invalidate(quotationDetailProvider);
  ref.invalidate(saleListProvider);
  ref.invalidate(saleDetailProvider);
  refreshParties(ref);
}
