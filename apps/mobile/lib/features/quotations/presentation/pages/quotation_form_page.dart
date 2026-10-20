import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/format_utils.dart';
import '../../../../core/widgets/khata_snackbars.dart';
import '../../../../core/widgets/app_date_field.dart';
import '../../../parties/presentation/providers/party_providers.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../products/presentation/providers/product_providers.dart';
import '../../data/repositories/quotation_repository_impl.dart';
import '../../domain/entities/quotation_entity.dart';
import '../providers/quotation_providers.dart';
import '../../../../l10n/app_localizations.dart';

/// Create a quotation: pick a customer and build lines manually. Money is
/// entered in rupees and sent as integer paisa.
class QuotationFormPage extends ConsumerStatefulWidget {
  const QuotationFormPage({super.key});

  @override
  ConsumerState<QuotationFormPage> createState() => _QuotationFormPageState();
}

class _QuotationFormPageState extends ConsumerState<QuotationFormPage> {
  final _discountController = TextEditingController();
  final _notesController = TextEditingController();
  final _termsController = TextEditingController();

  final List<_LineControllers> _lines = [];
  int? _customerId;
  DateTime? _validUntil;
  String _status = 'Draft';
  bool _saving = false;

  @override
  void dispose() {
    _discountController.dispose();
    _notesController.dispose();
    _termsController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  // --- live totals (mirror the server's integer-paisa math) ---

  int get _subtotal => _lines.fold(0, (sum, l) => sum + l.draft.gross);
  int get _lineDiscount =>
      _lines.fold(0, (sum, l) => sum + l.draft.discountAmount);
  int get _tax => _lines.fold(0, (sum, l) => sum + l.draft.taxAmount);
  int get _headerDiscount => _paisa(_discountController.text);
  int get _total => _subtotal - _lineDiscount - _headerDiscount + _tax;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final theme = Theme.of(context);
    final customers = ref.watch(customerPickerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.newQuotation)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- customer ---
          DropdownButtonFormField<int?>(
            value: _customerId,
            decoration: InputDecoration(
              labelText: l10n.customer,
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              DropdownMenuItem<int?>(
                  value: null, child: Text(l10n.walkInNone)),
              for (final c in customers.valueOrNull ?? const [])
                DropdownMenuItem<int?>(value: c.id, child: Text(c.name)),
            ],
            onChanged: (value) => setState(() => _customerId = value),
          ),
          const SizedBox(height: 16),

          // --- line items ---
          Row(
            children: [
              Expanded(
                child: Text(l10n.items, style: theme.textTheme.titleSmall),
              ),
              TextButton.icon(
                onPressed: _addProduct,
                icon: const Icon(Icons.add),
                label: Text(l10n.addItem),
              ),
              TextButton(
                onPressed: _addFreeText,
                child: Text(l10n.addFreeText),
              ),
            ],
          ),
          if (_lines.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(l10n.noItemsYetAddProduct,
                    style: theme.textTheme.bodySmall),
              ),
            ),
          for (final line in _lines) _buildLine(line),
          const SizedBox(height: 12),

          // --- header discount ---
          TextField(
            controller: _discountController,
            decoration: InputDecoration(
              labelText: l10n.extraDiscountRs,
              border: OutlineInputBorder(),
              isDense: true,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // --- totals ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _totalRow('Subtotal', formatPaisa(_subtotal)),
                  if (_lineDiscount + _headerDiscount > 0)
                    _totalRow('Discount',
                        '-${formatPaisa(_lineDiscount + _headerDiscount)}'),
                  if (_tax > 0) _totalRow('Tax', formatPaisa(_tax)),
                  const Divider(),
                  _totalRow('Total', formatPaisa(_total), bold: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // --- valid until ---
          AppDateField(
            value: _validUntil,
            onChanged: (picked) => setState(() => _validUntil = picked),
            label: l10n.validUntil,
            placeholder: l10n.notSet,
            clearable: true,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          ),
          const SizedBox(height: 12),

          // --- status ---
          DropdownButtonFormField<String>(
            value: _status,
            decoration: InputDecoration(
              labelText: l10n.status,
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              DropdownMenuItem(value: 'Draft', child: Text(l10n.draft)),
              DropdownMenuItem(value: 'Sent', child: Text(l10n.sent)),
            ],
            onChanged: (value) => setState(() => _status = value ?? 'Draft'),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: l10n.notes,
              border: OutlineInputBorder(),
              isDense: true,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _termsController,
            decoration: InputDecoration(
              labelText: l10n.terms,
              border: OutlineInputBorder(),
              isDense: true,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.check),
            label: Text(l10n.createQuotation),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  Widget _buildLine(_LineControllers line) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: line.description,
                    decoration: InputDecoration(
                      labelText: l10n.descriptionLabel,
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) => line.draft.description = value,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() {
                    _lines.remove(line);
                    line.dispose();
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _smallField(line.qty, 'Qty', onChanged: (_) {
                    line.draft.quantity = double.tryParse(line.qty.text) ?? 0;
                    setState(() {});
                  }),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _smallField(line.rate, l10n.rateRs, onChanged: (_) {
                    line.draft.unitPrice = _paisa(line.rate.text);
                    setState(() {});
                  }),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child:
                      _smallField(line.discount, l10n.discountRs, onChanged: (_) {
                    line.draft.discountAmount = _paisa(line.discount.text);
                    setState(() {});
                  }),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(l10n.lineTotalIs(formatPaisa(line.draft.lineTotal)),
                  style: theme.textTheme.labelMedium),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallField(TextEditingController controller, String label,
      {required ValueChanged<String> onChanged}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
    );
  }

  Widget _totalRow(String label, String value, {bool bold = false}) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }

  Future<void> _addProduct() async {
    final product = await showModalBottomSheet<ProductEntity>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ProductPickerSheet(),
    );
    if (product == null) return;

    setState(() {
      _lines.add(_LineControllers(QuotationLineDraft(
        productId: product.id,
        description: product.name,
        quantity: 1,
        unitPrice: product.sellingPrice,
        taxRateBps: product.taxRateBps,
      )));
    });
  }

  void _addFreeText() {
    setState(() => _lines.add(_LineControllers(QuotationLineDraft())));
  }


  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (_lines.isEmpty) {
      showInfoSnackBar(context, l10n.addAtLeastOneItem);
      return;
    }

    setState(() => _saving = true);
    try {
      final notes = _notesController.text.trim();
      final terms = _termsController.text.trim();
      await ref.read(quotationRepositoryProvider).createQuotation(
            customerId: _customerId,
            validUntil: _validUntil,
            items: _lines.map((l) => l.draft).toList(),
            discountAmount: _headerDiscount,
            notes: notes.isEmpty ? null : notes,
            terms: terms.isEmpty ? null : terms,
            status: _status,
          );
      refreshQuotations(ref);
      if (mounted) {
        context.go('/quotations');
        showInfoSnackBar(context, l10n.quotationCreated);
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static int _paisa(String text) {
    final rupees = double.tryParse(text.trim()) ?? 0;
    return (rupees * 100).round();
  }

}

/// Editable controllers for one line in the form.
class _LineControllers {
  final QuotationLineDraft draft;
  late final TextEditingController description =
      TextEditingController(text: draft.description);
  late final TextEditingController qty =
      TextEditingController(text: formatQuantity(draft.quantity));
  late final TextEditingController rate =
      TextEditingController(text: (draft.unitPrice / 100).toStringAsFixed(2));
  final TextEditingController discount = TextEditingController();

  _LineControllers(this.draft);

  void dispose() {
    description.dispose();
    qty.dispose();
    rate.dispose();
    discount.dispose();
  }
}

/// Searchable product picker shown when adding a line.
class _ProductPickerSheet extends ConsumerStatefulWidget {
  const _ProductPickerSheet();

  @override
  ConsumerState<_ProductPickerSheet> createState() =>
      _ProductPickerSheetState();
}

class _ProductPickerSheetState extends ConsumerState<_ProductPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final products = ref.watch(productPickerProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: l10n.searchProducts,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              Expanded(
                child: products.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) =>
                      Center(child: Text(l10n.couldNotLoad('$error'))),
                  data: (catalog) {
                    final query = _query.trim().toLowerCase();
                    final items = catalog
                        .where((p) =>
                            query.isEmpty ||
                            p.name.toLowerCase().contains(query) ||
                            (p.sku?.toLowerCase().contains(query) ?? false))
                        .toList();
                    if (items.isEmpty) {
                      return Center(child: Text(l10n.noProductsFound));
                    }
                    return ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final product = items[index];
                        return ListTile(
                          title: Text(product.name),
                          subtitle: Text(
                            '${formatPaisa(product.sellingPrice)}  •  '
                            '${formatQuantity(product.stockQuantity)} in stock',
                          ),
                          onTap: () => Navigator.of(context).pop(product),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
