import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/nepali_date_utils.dart';
import '../../domain/entities/quotation_entity.dart';
import '../providers/quotation_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/router/nav.dart';

/// Quotations list: search, status filter, and a link to each quotation.
class QuotationListPage extends ConsumerWidget {
  const QuotationListPage({super.key});

  static const _statuses = <String?>[
    null,
    'Draft',
    'Sent',
    'Accepted',
    'Rejected',
    'Expired',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final quotationsAsync = ref.watch(quotationListProvider);
    final status = ref.watch(quotationStatusFilterProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.quotations)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.searchQuotationOrCustomer,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              onChanged: (value) =>
                  ref.read(quotationSearchProvider.notifier).state = value,
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
                          .read(quotationStatusFilterProvider.notifier)
                          .state = option,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: quotationsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48),
                      const SizedBox(height: 12),
                      Text(l10n.couldNotLoadX(l10n.quotations, '$error'),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => refreshQuotations(ref),
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
              ),
              data: (quotations) {
                if (quotations.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.request_quote_outlined, size: 48),
                          SizedBox(height: 12),
                          Text(l10n.noQuotations),
                        ],
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => refreshQuotations(ref),
                  child: ListView.builder(
                    // Clear of the extended FAB, which otherwise covers the last row.
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: quotations.length,
                    itemBuilder: (context, index) =>
                        _QuotationTile(quotation: quotations[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openRoute(context, '/quotations/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.newQuotation),
      ),
    );
  }
}

/// Quotation-status colour, shared by the list and detail pages.
Color quotationStatusColor(BuildContext context, String status) {
  switch (status) {
    case 'Draft':
      return Colors.grey.shade600;
    case 'Sent':
      return Colors.blue.shade700;
    case 'Accepted':
      return Colors.green.shade700;
    case 'Rejected':
      return Colors.red.shade700;
    case 'Expired':
      return Colors.orange.shade800;
    default:
      return Colors.grey.shade600;
  }
}

class _QuotationTile extends StatelessWidget {
  final QuotationEntity quotation;

  const _QuotationTile({required this.quotation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = quotationStatusColor(context, quotation.status);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(Icons.request_quote_outlined, size: 18, color: color),
        ),
        title: Text(
          '${quotation.quoteNumber}  •  ${quotation.customerName ?? 'Walk-in'}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle:
            Text(_date(quotation.issueDate), style: theme.textTheme.bodySmall),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatPaisa(quotation.totalAmount),
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Chip(
              label: Text(quotation.status),
              visualDensity: VisualDensity.compact,
              side: BorderSide(color: color),
              labelStyle: TextStyle(color: color, fontSize: 12),
            ),
          ],
        ),
        onTap: () => openRoute(context, '/quotations/${quotation.id}'),
      ),
    );
  }

  static String _date(DateTime d) =>
      formatDisplayDate(d);
}
