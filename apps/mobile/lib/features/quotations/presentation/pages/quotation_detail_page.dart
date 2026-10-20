import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/scratch_files.dart';
import '../../../../core/widgets/khata_snackbars.dart';
import '../../../../core/utils/nepali_date_utils.dart';
import '../../data/repositories/quotation_repository_impl.dart';
import '../../domain/entities/quotation_entity.dart';
import '../providers/quotation_providers.dart';
import 'quotation_list_page.dart' show quotationStatusColor;
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/status_label.dart';

/// One quotation: header, totals, line items, notes/terms, a share action that
/// downloads the PDF, a convert-to-sale action, and a delete action.
class QuotationDetailPage extends ConsumerWidget {
  final int quotationId;

  const QuotationDetailPage({super.key, required this.quotationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);


    final quotationAsync = ref.watch(quotationDetailProvider(quotationId));
    final theme = Theme.of(context);
    final quotation = quotationAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.quotation),
        actions: [
          IconButton(
            tooltip: l10n.sharePdf,
            icon: const Icon(Icons.ios_share),
            onPressed: quotation == null
                ? null
                : () => _sharePdf(context, ref, quotation),
          ),
          IconButton(
            tooltip: l10n.delete,
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: quotationAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Text(l10n.couldNotLoadX(l10n.quotation, '$error'),
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () =>
                      ref.invalidate(quotationDetailProvider(quotationId)),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
        data: (quotation) => ListView(
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
                            quotation.quoteNumber,
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Chip(
                          label: Text(statusLabel(quotation.status, l10n)),
                          visualDensity: VisualDensity.compact,
                          side: BorderSide(
                              color: quotationStatusColor(
                                  context, quotation.status)),
                          labelStyle: TextStyle(
                              color: quotationStatusColor(
                                  context, quotation.status)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(quotation.customerName ?? l10n.walkInCustomer,
                        style: theme.textTheme.bodyMedium),
                    Text(l10n.issuedOn(_date(quotation.issueDate)),
                        style: theme.textTheme.bodySmall),
                    if (quotation.validUntil != null)
                      Text(l10n.validUntilOn(_date(quotation.validUntil!)),
                          style: theme.textTheme.bodySmall),
                    if (quotation.isConverted)
                      Text(l10n.convertedToSale(quotation.convertedSaleId!),
                          style: theme.textTheme.bodySmall),
                    const Divider(height: 24),
                    _SummaryRow(l10n.subtotal, formatPaisa(quotation.subtotal)),
                    if (quotation.discountAmount > 0)
                      _SummaryRow(l10n.discount,
                          '-${formatPaisa(quotation.discountAmount)}'),
                    if (quotation.taxAmount > 0)
                      _SummaryRow(l10n.tax, formatPaisa(quotation.taxAmount)),
                    _SummaryRow(l10n.total, formatPaisa(quotation.totalAmount),
                        bold: true),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(l10n.itemsCount(quotation.items.length),
                  style: theme.textTheme.titleSmall),
            ),
            for (final item in quotation.items)
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
            if (quotation.notes != null && quotation.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(l10n.notesLabel('${quotation.notes}'),
                    style: theme.textTheme.bodySmall),
              ),
            if (quotation.terms != null && quotation.terms!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(l10n.termsLabel('${quotation.terms}'),
                    style: theme.textTheme.bodySmall),
              ),
            if (quotation.canConvert)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                child: FilledButton.icon(
                  onPressed: () => _convert(context, ref, quotation),
                  icon: const Icon(Icons.swap_horiz),
                  label: Text(l10n.convertToSale),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Downloads the quotation PDF, writes it to a temp file and shares it.
  /// Falls back to a snackbar with the saved path if sharing is unavailable.
  ///
  /// On the web there is no temp directory to write to, so the user is told
  /// that plainly instead of being handed a `MissingPluginException`.
  Future<void> _sharePdf(
    BuildContext context,
    WidgetRef ref,
    QuotationEntity quotation,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      final bytes =
          await ref.read(quotationRepositoryProvider).downloadPdf(quotation.id);
      final path =
          await writeScratchFile('${quotation.quoteNumber}.pdf', bytes);
      if (path == null) {
        if (context.mounted) {
          showInfoSnackBar(context, l10n.fileSaveNotSupported);
        }
        return;
      }
      try {
        await Share.shareXFiles(
          [XFile(path)],
          subject: quotation.quoteNumber,
          text: l10n.quotationNumberLabel(quotation.quoteNumber),
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

  /// Asks for the sale type and paid amount, converts the quotation, then
  /// opens the created sale.
  Future<void> _convert(
    BuildContext context,
    WidgetRef ref,
    QuotationEntity quotation,
  ) async {
    final l10n = AppLocalizations.of(context);
    final draft = await showDialog<_ConvertDraft>(
      context: context,
      builder: (_) => const _ConvertDialog(),
    );
    if (draft == null) return;

    try {
      final sale = await ref.read(quotationRepositoryProvider).convertToSale(
            quotation.id,
            saleType: draft.saleType,
            paidAmount: draft.paidAmount,
          );
      final saleId = sale['id'] as int;
      refreshQuotations(ref);
      if (context.mounted) {
        showInfoSnackBar(context, l10n.convertedToSaleToast);
        context.go('/sales/$saleId');
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
        title: Text(l10n.deleteQuotationQuestion),
        content: Text(l10n.quotationDeleteNote),
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
      await ref.read(quotationRepositoryProvider).deleteQuotation(quotationId);
      refreshQuotations(ref);
      if (context.mounted) {
        context.go('/quotations');
        showInfoSnackBar(context, l10n.quotationDeleted);
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

/// Values returned by the convert dialog.
class _ConvertDraft {
  final String saleType;
  final int paidAmount;

  const _ConvertDraft({required this.saleType, required this.paidAmount});
}

/// Asks how the converted sale should be paid: type (Cash/Credit/Partial) and
/// the amount paid up front. Pops a [_ConvertDraft] on confirm.
class _ConvertDialog extends StatefulWidget {
  const _ConvertDialog();

  @override
  State<_ConvertDialog> createState() => _ConvertDialogState();
}

class _ConvertDialogState extends State<_ConvertDialog> {
  final _paidController = TextEditingController();
  String _saleType = 'Credit';

  @override
  void dispose() {
    _paidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);


    return AlertDialog(
      title: Text(l10n.convertToSale),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'Cash', label: Text(l10n.cash)),
                ButtonSegment(value: 'Credit', label: Text(l10n.credit)),
                ButtonSegment(value: 'Partial', label: Text(l10n.partial)),
              ],
              selected: {_saleType},
              onSelectionChanged: (selection) =>
                  setState(() => _saleType = selection.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _paidController,
              decoration: InputDecoration(
                labelText: l10n.paidAmountRs,
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () {
            final paid =
                _saleType == 'Partial' ? _paisa(_paidController.text) : 0;
            Navigator.of(context).pop(
              _ConvertDraft(saleType: _saleType, paidAmount: paid),
            );
          },
          child: Text(l10n.convert),
        ),
      ],
    );
  }

  static int _paisa(String text) {
    final rupees = double.tryParse(text.trim()) ?? 0;
    return (rupees * 100).round();
  }
}
