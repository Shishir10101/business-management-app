import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/format_utils.dart';
import '../../../../core/widgets/khata_snackbars.dart';
import '../../../../core/utils/nepali_date_utils.dart';
import '../../domain/entities/purchase_entity.dart';
import '../providers/purchase_providers.dart';
import 'purchase_list_page.dart' show purchaseStatusColor;
import '../../data/repositories/purchase_repository_impl.dart';
import '../../../../l10n/app_localizations.dart';

/// One purchase: header, totals, line items, and a delete (reversal) action.
class PurchaseDetailPage extends ConsumerWidget {
  final int purchaseId;

  const PurchaseDetailPage({super.key, required this.purchaseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);


    final purchaseAsync = ref.watch(purchaseDetailProvider(purchaseId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.purchase),
        actions: [
          IconButton(
            tooltip: l10n.delete,
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: purchaseAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Text(l10n.couldNotLoadX(l10n.purchase, '$error'),
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () =>
                      ref.invalidate(purchaseDetailProvider(purchaseId)),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
        data: (purchase) => ListView(
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
                          child: Text(purchase.billNumber,
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                        ),
                        Chip(
                          label: Text(purchase.paymentStatus),
                          visualDensity: VisualDensity.compact,
                          side: BorderSide(
                              color: purchaseStatusColor(
                                  context, purchase.paymentStatus)),
                          labelStyle: TextStyle(
                              color: purchaseStatusColor(
                                  context, purchase.paymentStatus)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(purchase.supplierName ?? l10n.noSupplier,
                        style: theme.textTheme.bodyMedium),
                    Text(_date(purchase.purchaseDate),
                        style: theme.textTheme.bodySmall),
                    const Divider(height: 24),
                    _SummaryRow('Subtotal', formatPaisa(purchase.subtotal)),
                    if (purchase.discountAmount > 0)
                      _SummaryRow('Discount',
                          '-${formatPaisa(purchase.discountAmount)}'),
                    if (purchase.taxAmount > 0)
                      _SummaryRow('Tax', formatPaisa(purchase.taxAmount)),
                    _SummaryRow('Total', formatPaisa(purchase.totalAmount),
                        bold: true),
                    _SummaryRow('Paid', formatPaisa(purchase.paidAmount)),
                    _SummaryRow('Due', formatPaisa(purchase.dueAmount),
                        color: purchase.dueAmount > 0
                            ? theme.colorScheme.error
                            : null),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(l10n.itemsCount(purchase.items.length),
                  style: theme.textTheme.titleSmall),
            ),
            for (final item in purchase.items)
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
            if (purchase.notes != null && purchase.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(l10n.notesLabel('${purchase.notes}'),
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
        title: Text(l10n.deletePurchaseQuestion),
        content: Text(
            '${l10n.purchaseDeleteNoteFull} ${l10n.purchaseKeptAsReversed}'),
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
      await ref.read(purchaseRepositoryProvider).deletePurchase(purchaseId);
      refreshPurchases(ref);
      if (context.mounted) {
        context.go('/purchases');
        showInfoSnackBar(context, l10n.purchaseReversed);
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
