import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/format_utils.dart';
import '../../../../core/widgets/khata_snackbars.dart';
import '../../../../core/utils/nepali_date_utils.dart';
import '../../domain/entities/sale_entity.dart';
import '../providers/sale_providers.dart';
import 'sale_list_page.dart' show saleStatusColor;
import '../../data/repositories/sale_repository_impl.dart';
import '../../../../l10n/app_localizations.dart';

/// One sale: header, totals, line items, and a delete (reversal) action.
class SaleDetailPage extends ConsumerWidget {
  final int saleId;

  const SaleDetailPage({super.key, required this.saleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);


    final saleAsync = ref.watch(saleDetailProvider(saleId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sale),
        actions: [
          IconButton(
            tooltip: l10n.delete,
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: saleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Text(l10n.couldNotLoadX(l10n.sale, '$error'),
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => ref.invalidate(saleDetailProvider(saleId)),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
        data: (sale) => ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(sale.invoiceNumber,
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                        ),
                        Chip(
                          label: Text(sale.paymentStatus),
                          visualDensity: VisualDensity.compact,
                          side: BorderSide(
                              color:
                                  saleStatusColor(context, sale.paymentStatus)),
                          labelStyle: TextStyle(
                              color:
                                  saleStatusColor(context, sale.paymentStatus)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(sale.customerName ?? l10n.walkInCustomer,
                        style: theme.textTheme.bodyMedium),
                    Text(_date(sale.saleDate),
                        style: theme.textTheme.bodySmall),
                    const Divider(height: 24),
                    _SummaryRow('Subtotal', formatPaisa(sale.subtotal)),
                    if (sale.discountAmount > 0)
                      _SummaryRow(
                          l10n.discount, '-${formatPaisa(sale.discountAmount)}'),
                    if (sale.taxAmount > 0)
                      _SummaryRow('Tax', formatPaisa(sale.taxAmount)),
                    _SummaryRow('Total', formatPaisa(sale.totalAmount),
                        bold: true),
                    _SummaryRow('Paid', formatPaisa(sale.paidAmount)),
                    _SummaryRow('Due', formatPaisa(sale.dueAmount),
                        color: sale.dueAmount > 0
                            ? theme.colorScheme.error
                            : null),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(l10n.itemsCount(sale.items.length),
                  style: theme.textTheme.titleSmall),
            ),
            for (final item in sale.items)
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  title: Text(item.productName),
                  subtitle: Text(
                    '${formatQuantity(item.quantity)} × ${formatPaisa(item.unitPrice)}'
                    '${item.discountAmount > 0 ? '  − ${formatPaisa(item.discountAmount)}' : ''}',
                  ),
                  trailing: Text(formatPaisa(item.lineTotal),
                      style: theme.textTheme.titleSmall),
                ),
              ),
            if (sale.notes != null && sale.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(l10n.notesLabel('${sale.notes}'),
                    style: theme.textTheme.bodySmall),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteSaleQuestion),
        content: Text(
            '${l10n.saleDeleteNoteFull} ${l10n.saleKeptAsReversed}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(saleRepositoryProvider).deleteSale(saleId);
      refreshSales(ref);
      if (context.mounted) {
        context.go('/sales');
        showInfoSnackBar(context, l10n.saleReversed);
      }
    } catch (e) {
      if (context.mounted) showErrorSnackBar(context, '$e');
    }
  }

  static String _date(DateTime d) =>
      formatDisplayDate(d);
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;

  const _SummaryRow(this.label, this.value, {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: color,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}
