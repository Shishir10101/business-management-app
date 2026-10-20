import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/nepali_date_utils.dart';
import '../../domain/entities/invoice_entity.dart';
import '../providers/invoice_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/router/nav.dart';

/// Invoices list: search, status filter, and a link to each invoice.
class InvoiceListPage extends ConsumerWidget {
  const InvoiceListPage({super.key});

  static const _statuses = <String?>[
    null,
    'Draft',
    'Sent',
    'Paid',
    'Partial',
    'Overdue',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final invoicesAsync = ref.watch(invoiceListProvider);
    final status = ref.watch(invoiceStatusFilterProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.invoices)),
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
                  ref.read(invoiceSearchProvider.notifier).state = value,
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
                      label: Text(option ?? 'All'),
                      selected: status == option,
                      onSelected: (_) => ref
                          .read(invoiceStatusFilterProvider.notifier)
                          .state = option,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: invoicesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48),
                      const SizedBox(height: 12),
                      Text(l10n.couldNotLoadX(l10n.invoices, '$error'),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => refreshInvoices(ref),
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
              ),
              data: (invoices) {
                if (invoices.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.description_outlined, size: 48),
                          SizedBox(height: 12),
                          Text(l10n.noInvoices),
                        ],
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => refreshInvoices(ref),
                  child: ListView.builder(
                    // Clear of the extended FAB, which otherwise covers the last row.
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: invoices.length,
                    itemBuilder: (context, index) =>
                        _InvoiceTile(invoice: invoices[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openRoute(context, '/invoices/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.newInvoice),
      ),
    );
  }
}

/// Invoice-status colour, shared by the list and detail pages.
Color invoiceStatusColor(BuildContext context, String status) {
  switch (status) {
    case 'Draft':
      return Colors.grey.shade600;
    case 'Sent':
      return Colors.blue.shade700;
    case 'Paid':
      return Colors.green.shade700;
    case 'Partial':
      return Colors.orange.shade800;
    case 'Overdue':
      return Colors.red.shade700;
    default:
      return Colors.grey.shade600;
  }
}

class _InvoiceTile extends StatelessWidget {
  final InvoiceEntity invoice;

  const _InvoiceTile({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = invoiceStatusColor(context, invoice.status);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(Icons.description_outlined, size: 18, color: color),
        ),
        title: Text(
          '${invoice.invoiceNumber}  •  ${invoice.customerName ?? 'Walk-in'}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle:
            Text(_date(invoice.issueDate), style: theme.textTheme.bodySmall),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatPaisa(invoice.totalAmount),
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Chip(
              label: Text(invoice.status),
              visualDensity: VisualDensity.compact,
              side: BorderSide(color: color),
              labelStyle: TextStyle(color: color, fontSize: 12),
            ),
          ],
        ),
        onTap: () => openRoute(context, '/invoices/${invoice.id}'),
      ),
    );
  }

  static String _date(DateTime d) =>
      formatDisplayDate(d);
}
