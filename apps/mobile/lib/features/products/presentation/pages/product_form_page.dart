import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/offline/offline_providers.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/widgets/khata_snackbars.dart';
import '../../domain/entities/product_entity.dart';
import '../providers/product_providers.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../../../l10n/app_localizations.dart';

/// Product form for create (productId == null) and edit.
/// Prices are entered in rupees and converted to integer paisa before sending.
class ProductFormPage extends ConsumerStatefulWidget {
  final int? productId;

  const ProductFormPage({super.key, this.productId});

  @override
  ConsumerState<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends ConsumerState<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  final _sellingController = TextEditingController();
  final _wholesaleController = TextEditingController();
  final _taxController = TextEditingController();
  final _openingController = TextEditingController();
  final _minController = TextEditingController();

  int? _categoryId;
  int? _unitId;
  bool _isActive = true;
  bool _saving = false;
  bool _loaded = false;

  bool get _isEdit => widget.productId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _descriptionController.dispose();
    _costController.dispose();
    _sellingController.dispose();
    _wholesaleController.dispose();
    _taxController.dispose();
    _openingController.dispose();
    _minController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);


    final productAsync =
        _isEdit ? ref.watch(productDetailProvider(widget.productId!)) : null;
    final categoriesAsync = ref.watch(categoriesProvider);
    final unitsAsync = ref.watch(unitsProvider);

    // Populate the form once, when an edit payload arrives.
    if (_isEdit && !_loaded && productAsync?.valueOrNull != null) {
      _loaded = true;
      _fillFrom(productAsync!.valueOrNull!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l10n.editProduct : l10n.newProduct),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: l10n.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_isEdit && productAsync!.isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: LinearProgressIndicator(),
              ),
            if (_isEdit && productAsync!.hasError)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  l10n.couldNotLoadProduct('${productAsync.error}'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.productNameRequired),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? l10n.nameRequired
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _skuController,
              decoration: InputDecoration(labelText: l10n.sku),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _barcodeController,
              decoration: InputDecoration(labelText: l10n.barcode),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              value: _categoryId,
              decoration: InputDecoration(labelText: l10n.category),
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.noCategory)),
                ...(categoriesAsync.valueOrNull ?? [])
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        )),
              ],
              onChanged: (value) => setState(() => _categoryId = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              value: _unitId,
              decoration: InputDecoration(labelText: l10n.unit),
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.noUnit)),
                ...(unitsAsync.valueOrNull ?? []).map((u) => DropdownMenuItem(
                      value: u.id,
                      child: Text(l10n.unitNameShort(u.name, u.shortName)),
                    )),
              ],
              onChanged: (value) => setState(() => _unitId = value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _costController,
              decoration: InputDecoration(
                labelText: l10n.costPriceRs,
                hintText: l10n.quantityExample16,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: _moneyValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sellingController,
              decoration: InputDecoration(
                labelText: l10n.sellingPriceRsRequired,
                hintText: l10n.amountExample,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                final base = _moneyValidator(value);
                if (base != null) return base;
                if (double.tryParse(value!.trim()) == null) {
                  return l10n.amountInvalid;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _wholesaleController,
              decoration: InputDecoration(
                labelText: l10n.wholesalePriceRs,
                hintText: l10n.optional,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: _moneyValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _taxController,
              decoration: InputDecoration(
                labelText: l10n.taxRatePercent,
                hintText: l10n.taxExample,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                final parsed = double.tryParse(value.trim());
                if (parsed == null || parsed < 0 || parsed > 100) {
                  return l10n.percentRange;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            if (!_isEdit)
              TextFormField(
                controller: _openingController,
                decoration: InputDecoration(
                  labelText: l10n.openingStockQuantity,
                  hintText: l10n.rateExample,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: _quantityValidator,
              ),
            if (!_isEdit) const SizedBox(height: 12),
            TextFormField(
              controller: _minController,
              decoration: InputDecoration(
                labelText: l10n.minQuantity,
                hintText: l10n.minimumQuantityHint,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: _quantityValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: l10n.descriptionLabel),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: Text(l10n.active),
              subtitle: Text(
                  l10n.inactiveProductsNote),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check),
              label: Text(_isEdit ? l10n.saveChanges : l10n.createProduct),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.pop(),
              child: Text(l10n.cancel),
            ),
          ],
        ),
      ),
    );
  }

  void _fillFrom(ProductEntity product) {
    _nameController.text = product.name;
    _skuController.text = product.sku ?? '';
    _barcodeController.text = product.barcode ?? '';
    _descriptionController.text = product.description ?? '';
    _costController.text = _rupeesText(product.costPrice);
    _sellingController.text = _rupeesText(product.sellingPrice);
    _wholesaleController.text = product.wholesalePrice != null
        ? _rupeesText(product.wholesalePrice!)
        : '';
    _taxController.text =
        product.taxRateBps == 0 ? '' : (product.taxRateBps / 100).toString();
    _minController.text = formatQuantity(product.minQuantity);
    _categoryId = product.categoryId;
    _unitId = product.unitId;
    _isActive = product.isActive;
  }

  static String _rupeesText(int paisa) => (paisa / 100).toStringAsFixed(2);

  String? _moneyValidator(String? value) {
    final l10n = AppLocalizations.of(context);
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text);
    if (parsed == null || parsed < 0) return l10n.amountInvalid;
    return null;
  }

  String? _quantityValidator(String? value) {
    final l10n = AppLocalizations.of(context);
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text);
    if (parsed == null || parsed < 0) return l10n.quantityInvalid;
    return null;
  }

  int _paisa(String text) {
    final rupees = double.tryParse(text.trim()) ?? 0;
    return (rupees * 100).round();
  }

  int _bps(String text) {
    final percent = double.tryParse(text.trim()) ?? 0;
    return (percent * 100).round();
  }

  double _quantity(String text) => double.tryParse(text.trim()) ?? 0;

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final queue = ref.read(offlineQueueProvider);
    final queuedBefore = queue.queuedCount;
    try {
      final repository = ref.read(productRepositoryProvider);
      final name = _nameController.text.trim();
      final sku = _skuController.text.trim();
      final barcode = _barcodeController.text.trim();
      final description = _descriptionController.text.trim();

      if (_isEdit) {
        await repository.updateProduct(
          widget.productId!,
          name: name,
          categoryId: _categoryId,
          unitId: _unitId,
          sku: sku.isEmpty ? null : sku,
          barcode: barcode.isEmpty ? null : barcode,
          description: description.isEmpty ? null : description,
          costPrice: _paisa(_costController.text),
          sellingPrice: _paisa(_sellingController.text),
          wholesalePrice: _wholesaleController.text.trim().isEmpty
              ? null
              : _paisa(_wholesaleController.text),
          taxRateBps: _bps(_taxController.text),
          isActive: _isActive,
          minQuantity: _quantity(_minController.text),
        );
      } else {
        await repository.createProduct(
          name: name,
          categoryId: _categoryId,
          unitId: _unitId,
          sku: sku.isEmpty ? null : sku,
          barcode: barcode.isEmpty ? null : barcode,
          description: description.isEmpty ? null : description,
          costPrice: _paisa(_costController.text),
          sellingPrice: _paisa(_sellingController.text),
          wholesalePrice: _wholesaleController.text.trim().isEmpty
              ? null
              : _paisa(_wholesaleController.text),
          taxRateBps: _bps(_taxController.text),
          isActive: _isActive,
          openingQuantity: _quantity(_openingController.text),
          minQuantity: _quantity(_minController.text),
        );
      }

      refreshCatalog(ref);
      if (_isEdit) ref.invalidate(productDetailProvider(widget.productId!));
      if (mounted) {
        _leaveForm(context);
        if (queue.queuedCount > queuedBefore) {
          showQueuedOfflineSnackBar(context, l10n.savedOffline);
        } else {
          showInfoSnackBar(
            context,
            _isEdit ? l10n.productSaved : l10n.productCreated,
          );
        }
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteProductQuestion),
        content: Text(
            l10n.deleteProductWarning),
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
    final queue = ref.read(offlineQueueProvider);
    final queuedBefore = queue.queuedCount;
    try {
      await ref
          .read(productRepositoryProvider)
          .deleteProduct(widget.productId!);
      refreshCatalog(ref);
      if (mounted) {
        _leaveForm(context);
        if (queue.queuedCount > queuedBefore) {
          showQueuedOfflineSnackBar(context, l10n.savedOffline);
        } else {
          showInfoSnackBar(context, l10n.productDeleted);
        }
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, '$e');
    }
  }

  /// Closes the form, or opens the catalog when there is nothing to pop.
  ///
  /// A form can be the first route (deep link, notification, browser reload),
  /// and `context.pop()` then throws "There is nothing to pop" *after* the
  /// write already succeeded — the user would see an error for a save that
  /// worked.
  void _leaveForm(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/products');
  }
}
