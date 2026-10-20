import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/offline/offline_providers.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/nepali_validators.dart';
import '../../../../core/widgets/khata_snackbars.dart';
import '../../../../core/widgets/nepal_address_fields.dart';
import '../../domain/entities/party_entity.dart';
import '../providers/party_providers.dart';
import '../../data/repositories/party_repository_impl.dart';
import '../../../../l10n/app_localizations.dart';

/// Create/edit form for a customer or supplier. Money is entered in rupees
/// and converted to integer paisa before sending. In edit mode, changing the
/// opening balance appends an adjustment to the party's khata ledger.
class PartyFormPage extends ConsumerStatefulWidget {
  final PartyKind kind;
  final int? partyId;

  const PartyFormPage({super.key, required this.kind, this.partyId});

  @override
  ConsumerState<PartyFormPage> createState() => _PartyFormPageState();
}

class _PartyFormPageState extends ConsumerState<PartyFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _panController = TextEditingController();
  final _notesController = TextEditingController();
  final _openingController = TextEditingController();
  final _creditLimitController = TextEditingController();

  /// Province/district/municipality, chosen through the cascading widget.
  NepalAddress _address = const NepalAddress();

  bool _isActive = true;
  bool _saving = false;
  bool _loaded = false;

  bool get _isEdit => widget.partyId != null;
  bool get _isCustomer => widget.kind == PartyKind.customer;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _panController.dispose();
    _notesController.dispose();
    _openingController.dispose();
    _creditLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var loading = false;
    Object? loadError;

    if (_isEdit && _isCustomer) {
      final detail = ref.watch(customerDetailProvider(widget.partyId!));
      loading = detail.isLoading;
      loadError = detail.error;
      if (!_loaded && detail.valueOrNull != null) {
        _loaded = true;
        _fillFromCustomer(detail.valueOrNull!);
      }
    } else if (_isEdit) {
      final detail = ref.watch(supplierDetailProvider(widget.partyId!));
      loading = detail.isLoading;
      loadError = detail.error;
      if (!_loaded && detail.valueOrNull != null) {
        _loaded = true;
        _fillFromSupplier(detail.valueOrNull!);
      }
    }

    return _buildScaffold(context, loading: loading, loadError: loadError);
  }

  Widget _buildScaffold(BuildContext context,
      {required bool loading, Object? loadError}) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit
            ? l10n.editKind(_isCustomer ? 'customer' : 'supplier')
            : l10n.newKind(_isCustomer ? 'customer' : 'supplier')),
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
            if (loading)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: LinearProgressIndicator(),
              ),
            if (loadError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  l10n.couldNotLoad('$loadError'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.nameRequired),
              textCapitalization: TextCapitalization.words,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? l10n.nameRequired
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: l10n.phoneLabel),
              keyboardType: TextInputType.phone,
              validator: _phoneValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(labelText: l10n.email),
              keyboardType: TextInputType.emailAddress,
              validator: _emailValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(labelText: l10n.address),
            ),
            const SizedBox(height: 12),
            NepalAddressFields(
              onChanged: (value) => _address = value,
              initialProvince: _address.province,
              initialDistrict: _address.district,
              initialMunicipality: _address.municipality,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _panController,
              decoration: InputDecoration(labelText: l10n.pan),
              validator: _panValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _openingController,
              decoration: InputDecoration(
                labelText: l10n.openingBalanceRs,
                hintText: _isCustomer
                    ? 'positive = they owe you'
                    : 'positive = you owe them',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              validator: _moneyValidator,
            ),
            if (_isCustomer) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _creditLimitController,
                decoration: InputDecoration(
                  labelText: l10n.creditLimitRs,
                  hintText: l10n.optional,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: _moneyValidator,
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(labelText: l10n.notes),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: Text(l10n.active),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check),
              label: Text(_isEdit ? l10n.saveChanges : l10n.create),
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

  void _fillFromCustomer(CustomerEntity party) {
    _nameController.text = party.name;
    _phoneController.text = party.phoneNumber ?? '';
    _emailController.text = party.email ?? '';
    _addressController.text = party.addressLine ?? '';
    _address = NepalAddress(
      district: party.district,
      municipality: party.city,
    );
    _panController.text = party.panNumber ?? '';
    _notesController.text = party.notes ?? '';
    _openingController.text = _rupeesText(party.openingBalance);
    _creditLimitController.text =
        party.creditLimit != null ? _rupeesText(party.creditLimit!) : '';
    _isActive = party.isActive;
  }

  void _fillFromSupplier(SupplierEntity party) {
    _nameController.text = party.name;
    _phoneController.text = party.phoneNumber ?? '';
    _emailController.text = party.email ?? '';
    _addressController.text = party.addressLine ?? '';
    _address = NepalAddress(
      district: party.district,
      municipality: party.city,
    );
    _panController.text = party.panNumber ?? '';
    _notesController.text = party.notes ?? '';
    _openingController.text = _rupeesText(party.openingBalance);
    _isActive = party.isActive;
  }

  static String _rupeesText(int paisa) {
    if (paisa == 0) return '';
    final negative = paisa < 0;
    final abs = paisa.abs();
    final text = (abs / 100).toStringAsFixed(2);
    return negative ? '-$text' : text;
  }

  String? _phoneValidator(String? value) {
    final l10n = AppLocalizations.of(context);
    if (!isValidNepaliPhone(value)) {
      return l10n.phoneInvalidNepali;
    }
    return null;
  }

  String? _emailValidator(String? value) {
    final l10n = AppLocalizations.of(context);
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
      return l10n.emailAddressRequired;
    }
    return null;
  }

  String? _panValidator(String? value) {
    final l10n = AppLocalizations.of(context);
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (!RegExp(r'^\d{9}$').hasMatch(text)) return l10n.panMustBe9Digits;
    return null;
  }

  String? _moneyValidator(String? value) {
    final l10n = AppLocalizations.of(context);
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text);
    if (parsed == null) return l10n.amountInvalidFull;
    return null;
  }

  int _paisa(String text) {
    final rupees = double.tryParse(text.trim()) ?? 0;
    return (rupees * 100).round();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context);
    // A save that cannot reach the server is queued instead of failing; the
    // counter tells this form whether to say "saved offline".
    final queue = ref.read(offlineQueueProvider);
    final queuedBefore = queue.queuedCount;
    try {
      final repository = ref.read(partyRepositoryProvider);
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final email = _emailController.text.trim();
      final address = _addressController.text.trim();
      final city = _address.municipality?.trim() ?? '';
      final district = _address.district?.trim() ?? '';
      final pan = _panController.text.trim();
      final notes = _notesController.text.trim();
      final opening = _paisa(_openingController.text);
      final creditLimitText = _creditLimitController.text.trim();

      if (_isEdit) {
        if (_isCustomer) {
          await repository.updateCustomer(
            widget.partyId!,
            name: name,
            phoneNumber: phone.isEmpty ? null : phone,
            email: email.isEmpty ? null : email,
            addressLine: address.isEmpty ? null : address,
            city: city.isEmpty ? null : city,
            district: district.isEmpty ? null : district,
            openingBalance: opening,
            panNumber: pan.isEmpty ? null : pan,
            creditLimit:
                creditLimitText.isEmpty ? null : _paisa(creditLimitText),
            notes: notes.isEmpty ? null : notes,
            isActive: _isActive,
          );
        } else {
          await repository.updateSupplier(
            widget.partyId!,
            name: name,
            phoneNumber: phone.isEmpty ? null : phone,
            email: email.isEmpty ? null : email,
            addressLine: address.isEmpty ? null : address,
            city: city.isEmpty ? null : city,
            district: district.isEmpty ? null : district,
            openingBalance: opening,
            panNumber: pan.isEmpty ? null : pan,
            notes: notes.isEmpty ? null : notes,
            isActive: _isActive,
          );
        }
      } else {
        if (_isCustomer) {
          await repository.createCustomer(
            name: name,
            phoneNumber: phone.isEmpty ? null : phone,
            email: email.isEmpty ? null : email,
            addressLine: address.isEmpty ? null : address,
            city: city.isEmpty ? null : city,
            district: district.isEmpty ? null : district,
            openingBalance: opening,
            panNumber: pan.isEmpty ? null : pan,
            creditLimit:
                creditLimitText.isEmpty ? null : _paisa(creditLimitText),
            notes: notes.isEmpty ? null : notes,
            isActive: _isActive,
          );
        } else {
          await repository.createSupplier(
            name: name,
            phoneNumber: phone.isEmpty ? null : phone,
            email: email.isEmpty ? null : email,
            addressLine: address.isEmpty ? null : address,
            city: city.isEmpty ? null : city,
            district: district.isEmpty ? null : district,
            openingBalance: opening,
            panNumber: pan.isEmpty ? null : pan,
            notes: notes.isEmpty ? null : notes,
            isActive: _isActive,
          );
        }
      }

      refreshParties(ref);
      if (mounted) {
        _leaveForm(context);
        if (queue.queuedCount > queuedBefore) {
          showQueuedOfflineSnackBar(context, l10n.savedOffline);
        } else {
          showInfoSnackBar(context, _isEdit ? l10n.saved : l10n.created);
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
        title: Text(l10n.deletePartyQuestion(
            _isCustomer ? l10n.customer.toLowerCase() : l10n.supplier.toLowerCase())),
        content: Text(
            l10n.partyDeleteNote),
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
      final repository = ref.read(partyRepositoryProvider);
      if (_isCustomer) {
        await repository.deleteCustomer(widget.partyId!);
      } else {
        await repository.deleteSupplier(widget.partyId!);
      }
      refreshParties(ref);
      if (mounted) {
        _leaveForm(context);
        showInfoSnackBar(context, l10n.deleted);
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, '$e');
    }
  }

  /// Closes the form, or opens the list when there is nothing to pop.
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
    context.go(_isCustomer ? '/customers' : '/suppliers');
  }
}
