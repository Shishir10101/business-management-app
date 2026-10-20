import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../parties/presentation/providers/party_providers.dart';
import '../../data/repositories/invoice_repository_impl.dart';
import '../../domain/entities/invoice_entity.dart';

/// Current search text for the invoice list.
final invoiceSearchProvider = StateProvider<String>((ref) => '');

/// Status filter ('Draft' | 'Sent' | 'Paid' | 'Partial' | 'Overdue';
/// null = all).
final invoiceStatusFilterProvider = StateProvider<String?>((ref) => null);

/// Invoices of the active business, newest first.
final invoiceListProvider = FutureProvider<List<InvoiceEntity>>((ref) async {
  final page = await ref.read(invoiceRepositoryProvider).getInvoices(
        search: ref.watch(invoiceSearchProvider),
        status: ref.watch(invoiceStatusFilterProvider),
        pageSize: 100,
      );
  return page.data;
});

/// Full invoice by id (detail page).
final invoiceDetailProvider =
    FutureProvider.family<InvoiceEntity, int>((ref, id) async {
  return ref.read(invoiceRepositoryProvider).getInvoice(id);
});

/// Refreshes invoices and the customer khata they may reference.
void refreshInvoices(WidgetRef ref) {
  ref.invalidate(invoiceListProvider);
  ref.invalidate(invoiceDetailProvider);
  refreshParties(ref);
}
