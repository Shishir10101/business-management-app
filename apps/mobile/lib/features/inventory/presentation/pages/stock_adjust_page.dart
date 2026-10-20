import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/format_utils.dart';
import '../../../../core/widgets/khata_snackbars.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../providers/inventory_providers.dart';
import '../../data/repositories/inventory_repository_impl.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/router/nav.dart';

/// Stock adjustment page for one product: quick +/- buttons plus a custom
/// signed quantity and notes. Each save appends an immutable movement.
class StockAdjustPage extends ConsumerStatefulWidget {
  final int productId;

  const StockAdjustPage({super.key, required this.productId});

  @override
  ConsumerState<StockAdjustPage> createState() => _StockAdjustPageState();
}

class _StockAdjustPageState extends ConsumerState<StockAdjustPage> {
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  ProductEntity? _findProduct() {
    final products = ref.watch(inventoryListProvider).valueOrNull?.data ??
        const <ProductEntity>[];
    for (final product in products) {
      if (product.id == widget.productId) return product;
    }
    return null;
  }

  Future<void> _apply(double quantity) async {
    setState(() => _saving = true);
    try {
      final result = await ref.read(inventoryRepositoryProvider).adjustStock(
            widget.productId,
            quantity: quantity,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );
      refreshInventory(ref);
      if (mounted) {
        showInfoSnackBar(
          context,
          '${result.productName}: ${formatQuantity(result.quantity)} in stock',
        );
        _notesController.clear();
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final product = _findProduct();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adjustStock),
        actions: [
          IconButton(
            tooltip: l10n.movementHistory,
            icon: const Icon(Icons.history),
            onPressed: () =>
                openRoute(context, '/inventory/${widget.productId}/movements'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (product == null)
            Card(
              child: ListTile(
                leading: Icon(Icons.inventory_2_outlined),
                title: Text(l10n.loadingProduct),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.currentStockIs(formatQuantity(product.stockQuantity))}'
                      '${product.unitShortName != null ? ' ${product.unitShortName}' : ''}'
                      '${product.isLowStock ? ' (low!)' : ''}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            product.isLowStock ? theme.colorScheme.error : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(l10n.quickAdjust, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: _saving ? null : () => _apply(1),
                icon: const Icon(Icons.add),
                label: Text(l10n.plusOne),
              ),
              FilledButton.tonalIcon(
                onPressed: _saving ? null : () => _apply(10),
                icon: const Icon(Icons.add),
                label: Text(l10n.plusTen),
              ),
              FilledButton.tonalIcon(
                onPressed: _saving ? null : () => _apply(-1),
                icon: const Icon(Icons.remove),
                label: Text(l10n.minusOne),
              ),
              FilledButton.tonalIcon(
                onPressed: _saving ? null : () => _apply(-10),
                icon: const Icon(Icons.remove),
                label: Text(l10n.minusTen),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _quantityController,
            decoration: InputDecoration(
              labelText: l10n.customQuantityHint,
              hintText: l10n.quantityExample,
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true, signed: true),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: l10n.notesOptional,
              hintText: l10n.reasonExample,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving ? null : _applyCustom,
            icon: const Icon(Icons.check),
            label: Text(l10n.applyAdjustment),
          ),
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Future<void> _applyCustom() async {
    final l10n = AppLocalizations.of(context);
    final quantity = double.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity == 0) {
      showErrorSnackBar(context, l10n.enterNonZeroQuantity);
      return;
    }
    await _apply(quantity);
    _quantityController.clear();
  }
}
