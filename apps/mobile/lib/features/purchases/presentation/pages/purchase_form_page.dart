import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/format_utils.dart';
import '../../../../core/widgets/khata_snackbars.dart';
import '../../../parties/presentation/providers/party_providers.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../products/presentation/providers/product_providers.dart';
import '../../domain/entities/purchase_entity.dart';
import '../providers/purchase_providers.dart';
import '../../data/repositories/purchase_repository_impl.dart';
import '../../../../l10n/app_localizations.dart';

/// Create a purchase: pick a supplier, add product lines, and let the totals
/// and payment rules follow the purchase type. Money is entered in rupees and
/// sent as integer paisa. Line unit prices default to the product's cost price.
class PurchaseFormPage extends ConsumerStatefulWidget {
  const PurchaseFormPage({super.key});

  @override
  ConsumerState<PurchaseFormPage> createState() => _PurchaseFormPageState();
}

class _PurchaseFormPageState extends ConsumerState<PurchaseFormPage> {
  final _paidController = TextEditingController();
  final _discountController = TextEditingController();
  final _notesController = TextEditingController();

  final List<_LineControllers> _lines = [];
  int? _supplierId;
  String _purchaseType = 'Cash';
  bool _saving = false;

  @override
  void dispose() {
    _paidController.dispose();
    _discountController.dispose();
    _notesController.dispose();
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

  int get _paid => switch (_purchaseType) {
        'Cash' => _total,
        'Credit' => 0,
        _ => _paisa(_paidController.text),
      };

  int get _due => _total - _paid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final theme = Theme.of(context);
    final suppliers = ref.watch(supplierPickerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.newPurchase)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- supplier ---
          DropdownButtonFormField<int?>(
            value: _supplierId,
            decoration: InputDecoration(
              labelText: l10n.supplier,
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              DropdownMenuItem<int?>(value: null, child: Text(l10n.none)),
              for (final s in suppliers.valueOrNull ?? const [])
                DropdownMenuItem<int?>(value: s.id, child: Text(s.name)),
            ],
            onChanged: (value) => setState(() => _supplierId = value),
          ),
          SizedBox(height: 12),

          // --- purchase type ---
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'Cash', label: Text(l10n.cash)),
              ButtonSegment(value: 'Credit', label: Text(l10n.credit)),
              ButtonSegment(value: 'Partial', label: Text(l10n.partial)),
            ],
            selected: {_purchaseType},
            onSelectionChanged: (selection) =>
                setState(() => _purchaseType = selection.first),
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
          const SizedBox(height: 12),

          // --- paid amount (enabled only for partial) ---
          if (_purchaseType == 'Partial')
            TextField(
              controller: _paidController,
              decoration: InputDecoration(
                labelText: l10n.paidNowRs,
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            )
          else
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_purchaseType == 'Cash' ? l10n.paidInFull : 'Paid'),
              trailing:
                  Text(formatPaisa(_paid), style: theme.textTheme.titleMedium),
            ),
          if (_due > 0)
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                l10n.dueToSupplierKhata(formatPaisa(_due)),
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: theme.colorScheme.error),
              ),
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
          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.check),
            label: Text(l10n.createPurchase),
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
                  child: Text(line.draft.productName,
                      style: theme.textTheme.titleSmall),
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
            Row(
              children: [
                Expanded(
                  child: _smallField(line.qty, l10n.qty, onChanged: (_) {
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
      _lines.add(_LineControllers(PurchaseLineDraft(
        productId: product.id,
        productName: product.name,
        quantity: 1,
        unitPrice: product.costPrice,
        taxRateBps: product.taxRateBps,
      )));
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (_lines.isEmpty) {
      showInfoSnackBar(context, l10n.addAtLeastOneItem);
      return;
    }
    if (_due > 0 && _supplierId == null) {
      showInfoSnackBar(context, l10n.creditPurchaseNeedsSupplier);
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(purchaseRepositoryProvider).createPurchase(
            supplierId: _supplierId,
            purchaseType: _purchaseType,
            items: _lines.map((l) => l.draft).toList(),
            discountAmount: _headerDiscount,
            paidAmount: _paid,
            notes: _notesController.text.trim(),
          );
      refreshPurchases(ref);
      if (mounted) {
        context.go('/purchases');
        showInfoSnackBar(context, l10n.purchaseCreated);
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
  final PurchaseLineDraft draft;
  late final TextEditingController qty =
      TextEditingController(text: formatQuantity(draft.quantity));
  late final TextEditingController rate =
      TextEditingController(text: (draft.unitPrice / 100).toStringAsFixed(2));
  final TextEditingController discount = TextEditingController();

  _LineControllers(this.draft);

  void dispose() {
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
                            '${formatPaisa(product.costPrice)}  •  '
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
