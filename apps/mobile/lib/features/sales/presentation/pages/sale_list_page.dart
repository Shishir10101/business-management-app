import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/nepali_date_utils.dart';
import '../../domain/entities/sale_entity.dart';
import '../providers/sale_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/router/nav.dart';

/// Sales list: search, payment-status filter, and a link to each sale.
class SaleListPage extends ConsumerWidget {
  const SaleListPage({super.key});

  static const _statuses = <String?>[null, 'Paid', 'Partial', 'Unpaid'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final salesAsync = ref.watch(saleListProvider);
    final status = ref.watch(saleStatusFilterProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.sales)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.searchInvoiceOrCustomer,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              onChanged: (value) =>
                  ref.read(saleSearchProvider.notifier).state = value,
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                for (final option in _statuses)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_statusLabel(option, l10n)),
                      selected: status == option,
                      onSelected: (_) => ref
                          .read(saleStatusFilterProvider.notifier)
                          .state = option,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: salesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48),
                      const SizedBox(height: 12),
                      Text(l10n.couldNotLoadX(l10n.sales, '$error'),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => refreshSales(ref),
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
              ),
              data: (sales) {
                if (sales.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 48),
                          SizedBox(height: 12),
                          Text(l10n.noSales),
                        ],
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => refreshSales(ref),
                  child: ListView.builder(
                    // Clear of the extended FAB, which otherwise covers the last row.
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: sales.length,
                    itemBuilder: (context, index) =>
                        _SaleTile(sale: sales[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openRoute(context, '/sales/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.newSale),
      ),
    );
  }
}

/// Payment-status colour, shared by the list and detail pages.
Color saleStatusColor(BuildContext context, String status) {
  final scheme = Theme.of(context).colorScheme;
  switch (status) {
    case 'Paid':
      return Colors.green.shade700;
    case 'Partial':
      return Colors.orange.shade800;
    default:
      return scheme.error;
  }
}

class _SaleTile extends StatelessWidget {
  final SaleEntity sale;

  const _SaleTile({required this.sale});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              saleStatusColor(context, sale.paymentStatus).withOpacity(0.12),
          child: Icon(
            Icons.receipt_long_outlined,
            size: 18,
            color: saleStatusColor(context, sale.paymentStatus),
          ),
        ),
        title: Text(
            '${sale.invoiceNumber}  •  ${sale.customerName ?? 'Walk-in'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${_date(sale.saleDate)}  •  ${sale.saleType}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatPaisa(sale.totalAmount),
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              sale.dueAmount > 0
                  ? l10n.dueAmount(formatPaisa(sale.dueAmount))
                  : sale.paymentStatus,
              style: theme.textTheme.labelSmall?.copyWith(
                color: saleStatusColor(context, sale.paymentStatus),
              ),
            ),
          ],
        ),
        onTap: () => openRoute(context, '/sales/${sale.id}'),
      ),
    );
  }

  static String _date(DateTime d) =>
      formatDisplayDate(d);
}

/// Chip label for a payment-status filter option. The option itself stays a
/// wire value (it is sent to the API); only the label is localized.
String _statusLabel(String? status, AppLocalizations l10n) => switch (status) {
      'Paid' => l10n.paid,
      'Partial' => l10n.partial,
      'Unpaid' => l10n.unpaid,
      _ => l10n.all,
    };
