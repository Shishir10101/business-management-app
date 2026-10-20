import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/format_utils.dart';
import '../../../../core/widgets/khata_snackbars.dart';
import '../../../../core/widgets/app_date_field.dart';
import '../../../parties/presentation/providers/party_providers.dart';
import '../../../purchases/presentation/providers/purchase_providers.dart';
import '../../../sales/presentation/providers/sale_providers.dart';
import '../../data/repositories/payment_repository_impl.dart';
import '../../domain/entities/payment_entity.dart';
import '../providers/payment_providers.dart';
import '../../../../l10n/app_localizations.dart';

/// Record a payment: receive from a customer or pay a supplier, optionally
/// applying the money to one outstanding invoice or bill. Money is entered in
/// rupees and sent as integer paisa.
class PaymentFormPage extends ConsumerStatefulWidget {
  const PaymentFormPage({super.key});

  @override
  ConsumerState<PaymentFormPage> createState() => _PaymentFormPageState();
}

class _PaymentFormPageState extends ConsumerState<PaymentFormPage> {
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  String _mode = 'Receive';
  int? _partyId;
  int? _methodId;
  int? _saleId;
  int? _purchaseId;
  DateTime _paymentDate = DateTime.now();
  bool _defaultsLoaded = false;
  bool _saving = false;

  bool get _receiving => _mode == 'Receive';
  String get _partyType => _receiving ? 'Customer' : 'Supplier';

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final customers = ref.watch(customerPickerProvider);
    final suppliers = ref.watch(supplierPickerProvider);
    final methodsAsync = ref.watch(paymentMethodsProvider);
    final salesAsync = ref.watch(saleListProvider);
    final purchasesAsync = ref.watch(purchaseListProvider);

    // Pick the default payment method once the list has loaded.
    final methods = methodsAsync.valueOrNull;
    if (!_defaultsLoaded && methods != null) {
      _defaultsLoaded = true;
      final defaults = methods.where((m) => m.isActive && m.isDefault);
      if (defaults.isNotEmpty) _methodId = defaults.first.id;
    }
    final activeMethods = (methods ?? const <PaymentMethodEntity>[])
        .where((m) => m.isActive)
        .toList();
    final methodValue =
        activeMethods.any((m) => m.id == _methodId) ? _methodId : null;

    // Party choices depend on the direction.
    final partyItems = <DropdownMenuItem<int>>[
      if (_receiving)
        for (final c in customers.valueOrNull ?? const [])
          DropdownMenuItem<int>(value: c.id, child: Text(c.name))
      else
        for (final s in suppliers.valueOrNull ?? [])
          DropdownMenuItem<int>(value: s.id, child: Text(s.name)),
    ];

    // Outstanding documents for the selected party (invoice or bill).
    final documentItems = <DropdownMenuItem<int?>>[
      DropdownMenuItem<int?>(
          value: null, child: Text(l10n.onAccount)),
    ];
    int? selectedDue;
    if (_partyId != null && _receiving) {
      for (final sale in salesAsync.valueOrNull ?? const []) {
        if (sale.customerId != _partyId || sale.dueAmount <= 0) continue;
        documentItems.add(DropdownMenuItem<int?>(
          value: sale.id,
          child: Text(
              '${sale.invoiceNumber}  •  due ${formatPaisa(sale.dueAmount)}'),
        ));
        if (sale.id == _saleId) selectedDue = sale.dueAmount;
      }
    } else if (_partyId != null) {
      for (final purchase in purchasesAsync.valueOrNull ?? const []) {
        if (purchase.supplierId != _partyId || purchase.dueAmount <= 0)
          continue;
        documentItems.add(DropdownMenuItem<int?>(
          value: purchase.id,
          child: Text(
              '${purchase.billNumber}  •  due ${formatPaisa(purchase.dueAmount)}'),
        ));
        if (purchase.id == _purchaseId) selectedDue = purchase.dueAmount;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_receiving ? l10n.recordReceipt : l10n.recordPayment),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- direction ---
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'Receive',
                label: Text(l10n.receive),
                icon: Icon(Icons.arrow_downward),
              ),
              ButtonSegment(
                value: 'Pay',
                label: Text(l10n.pay),
                icon: Icon(Icons.arrow_upward),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (selection) => setState(() {
              _mode = selection.first;
              _partyId = null;
              _saleId = null;
              _purchaseId = null;
            }),
          ),
          const SizedBox(height: 16),

          // --- party ---
          DropdownButtonFormField<int>(
            value: _partyId,
            decoration: InputDecoration(
              labelText: _receiving ? 'Customer' : 'Supplier',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            items: partyItems,
            onChanged: (value) => setState(() {
              _partyId = value;
              _saleId = null;
              _purchaseId = null;
            }),
          ),
          const SizedBox(height: 12),

          // --- amount ---
          TextField(
            controller: _amountController,
            decoration: InputDecoration(
              labelText: l10n.amountRsRequired,
              border: OutlineInputBorder(),
              isDense: true,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),

          // --- payment method ---
          DropdownButtonFormField<int>(
            value: methodValue,
            decoration: InputDecoration(
              labelText: l10n.method,
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              DropdownMenuItem<int>(value: null, child: Text(l10n.none)),
              for (final m in activeMethods)
                DropdownMenuItem<int>(value: m.id, child: Text(m.name)),
            ],
            onChanged: (value) => setState(() => _methodId = value),
          ),
          const SizedBox(height: 12),

          // --- date ---
          AppDateField(
            value: _paymentDate,
            onChanged: (picked) {
              if (picked != null) setState(() => _paymentDate = picked);
            },
            label: l10n.dateLabel,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          ),
          const SizedBox(height: 12),

          // --- reference ---
          TextField(
            controller: _referenceController,
            decoration: InputDecoration(
              labelText: l10n.reference,
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),

          // --- notes ---
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: l10n.notes,
              border: OutlineInputBorder(),
              isDense: true,
            ),
            maxLines: 2,
          ),

          // --- apply to an outstanding document (optional) ---
          if (_partyId != null) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              value: _receiving ? _saleId : _purchaseId,
              decoration: InputDecoration(
                labelText: _receiving ? l10n.applyToInvoice : l10n.applyToBill,
                border: const OutlineInputBorder(),
                isDense: true,
                helperText: selectedDue != null
                    ? l10n.dueAmount(formatPaisa(selectedDue))
                    : null,
              ),
              items: documentItems,
              onChanged: (value) => setState(() {
                if (_receiving) {
                  _saleId = value;
                } else {
                  _purchaseId = value;
                }
              }),
            ),
          ],
          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.check),
            label: Text(l10n.recordPayment),
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


  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (_partyId == null) {
      showInfoSnackBar(
          context,
          l10n.selectPartyKind(
              _receiving ? l10n.customer.toLowerCase() : l10n.supplier.toLowerCase()));
      return;
    }
    final amount = _paisa(_amountController.text);
    if (amount <= 0) {
      showInfoSnackBar(context, l10n.enterAmountGreaterThanZero);
      return;
    }

    setState(() => _saving = true);
    try {
      final reference = _referenceController.text.trim();
      final notes = _notesController.text.trim();
      await ref.read(paymentRepositoryProvider).createPayment(
            partyType: _partyType,
            partyId: _partyId!,
            amount: amount,
            direction: _receiving ? 'In' : 'Out',
            paymentDate: _paymentDate,
            paymentMethodId: _methodId,
            reference: reference.isEmpty ? null : reference,
            notes: notes.isEmpty ? null : notes,
            saleId: _receiving ? _saleId : null,
            purchaseId: _receiving ? null : _purchaseId,
          );
      refreshPayments(ref);
      if (mounted) {
        context.go('/payments');
        showInfoSnackBar(context, l10n.paymentRecorded);
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
