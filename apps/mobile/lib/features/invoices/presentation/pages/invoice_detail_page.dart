import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/scratch_files.dart';
import '../../../../core/widgets/khata_snackbars.dart';
import '../../../../core/utils/nepali_date_utils.dart';
import '../../data/repositories/invoice_repository_impl.dart';
import '../../domain/entities/invoice_entity.dart';
import '../providers/invoice_providers.dart';
import 'invoice_list_page.dart' show invoiceStatusColor;
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/status_label.dart';

/// One invoice: header, totals, line items, notes/terms, a share action that
/// downloads the PDF, and a delete action.
class InvoiceDetailPage extends ConsumerWidget {
  final int invoiceId;

  const InvoiceDetailPage({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);


    final invoiceAsync = ref.watch(invoiceDetailProvider(invoiceId));
    final theme = Theme.of(context);
    final invoice = invoiceAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.invoice),
        actions: [
          IconButton(
            tooltip: l10n.sharePdf,
            icon: const Icon(Icons.ios_share),
            onPressed:
                invoice == null ? null : () => _sharePdf(context, ref, invoice),
          ),
          IconButton(
            tooltip: l10n.delete,
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: invoiceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Text(l10n.couldNotLoadX(l10n.invoice, '$error'),
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () =>
                      ref.invalidate(invoiceDetailProvider(invoiceId)),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
        data: (invoice) => ListView(
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
                          child: Text(
                            invoice.invoiceNumber,
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Chip(
                          label: Text(statusLabel(invoice.status, l10n)),
                          visualDensity: VisualDensity.compact,
                          side: BorderSide(
                              color:
                                  invoiceStatusColor(context, invoice.status)),
                          labelStyle: TextStyle(
                              color:
                                  invoiceStatusColor(context, invoice.status)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(invoice.customerName ?? l10n.walkInCustomer,
                        style: theme.textTheme.bodyMedium),
                    Text(l10n.issuedOn(_date(invoice.issueDate)),
                        style: theme.textTheme.bodySmall),
                    if (invoice.dueDate != null)
                      Text(l10n.dueOn(_date(invoice.dueDate!)),
                          style: theme.textTheme.bodySmall),
                    if (invoice.isFromSale &&
                        (invoice.saleInvoiceNumber ?? '').isNotEmpty)
                      Text(l10n.fromSale('${invoice.saleInvoiceNumber}'),
                          style: theme.textTheme.bodySmall),
                    const Divider(height: 24),
                    _SummaryRow(l10n.subtotal, formatPaisa(invoice.subtotal)),
                    if (invoice.discountAmount > 0)
                      _SummaryRow(l10n.discount,
                          '-${formatPaisa(invoice.discountAmount)}'),
                    if (invoice.taxAmount > 0)
                      _SummaryRow(l10n.tax, formatPaisa(invoice.taxAmount)),
                    _SummaryRow(l10n.total, formatPaisa(invoice.totalAmount),
                        bold: true),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(l10n.itemsCount(invoice.items.length),
                  style: theme.textTheme.titleSmall),
            ),
            for (final item in invoice.items)
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  title: Text(item.description),
                  subtitle: Text(
                    '${formatQuantity(item.quantity)} × ${formatPaisa(item.unitPrice)}'
                    '${item.discountAmount > 0 ? '  − ${formatPaisa(item.discountAmount)}' : ''}',
                  ),
                  trailing: Text(formatPaisa(item.lineTotal),
                      style: theme.textTheme.titleSmall),
                ),
              ),
            if (invoice.notes != null && invoice.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(l10n.notesLabel('${invoice.notes}'),
                    style: theme.textTheme.bodySmall),
              ),
            if (invoice.terms != null && invoice.terms!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(l10n.termsLabel('${invoice.terms}'),
                    style: theme.textTheme.bodySmall),
              ),
          ],
        ),
      ),
    );
  }

  /// Downloads the invoice PDF, writes it to a temp file and shares it.
  /// Falls back to a snackbar with the saved path if sharing is unavailable.
  ///
  /// On the web there is no temp directory to write to, so the user is told
  /// that plainly instead of being handed a `MissingPluginException`.
  Future<void> _sharePdf(
    BuildContext context,
    WidgetRef ref,
    InvoiceEntity invoice,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      final bytes =
          await ref.read(invoiceRepositoryProvider).downloadPdf(invoice.id);
      final path = await writeScratchFile('${invoice.invoiceNumber}.pdf', bytes);
      if (path == null) {
        if (context.mounted) {
          showInfoSnackBar(context, l10n.fileSaveNotSupported);
        }
        return;
      }
      try {
        await Share.shareXFiles(
          [XFile(path)],
          subject: invoice.invoiceNumber,
          text: l10n.invoiceNumberLabel(invoice.invoiceNumber),
        );
      } catch (_) {
        if (context.mounted) {
          showInfoSnackBar(context, l10n.savedTo('$path'));
        }
      }
    } catch (e) {
      if (context.mounted) showErrorSnackBar(context, '$e');
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteInvoiceQuestion),
        content: Text(l10n.invoiceDeleteNote),
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
      await ref.read(invoiceRepositoryProvider).deleteInvoice(invoiceId);
      refreshInvoices(ref);
      if (context.mounted) {
        context.go('/invoices');
        showInfoSnackBar(context, l10n.invoiceDeleted);
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
