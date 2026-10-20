import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/offline/offline_providers.dart';
import '../../../../core/widgets/khata_snackbars.dart';
import '../../../../core/widgets/app_date_field.dart';
import '../../domain/entities/income_entity.dart';
import '../providers/income_providers.dart';
import '../../data/repositories/income_repository_impl.dart';
import '../../../../l10n/app_localizations.dart';

/// Create/edit form for an income record. Money is entered in rupees and
/// converted to integer paisa before sending.
class IncomeFormPage extends ConsumerStatefulWidget {
  final int? incomeId;

  const IncomeFormPage({super.key, this.incomeId});

  @override
  ConsumerState<IncomeFormPage> createState() => _IncomeFormPageState();
}

class _IncomeFormPageState extends ConsumerState<IncomeFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _sourceController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _paymentMethodController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _incomeDate = DateTime.now();
  bool _saving = false;
  bool _loaded = false;

  bool get _isEdit => widget.incomeId != null;

  @override
  void dispose() {
    _sourceController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _paymentMethodController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);


    var loading = false;
    Object? loadError;

    if (_isEdit) {
      final detail = ref.watch(incomeDetailProvider(widget.incomeId!));
      loading = detail.isLoading;
      loadError = detail.error;
      if (!_loaded && detail.valueOrNull != null) {
        _loaded = true;
        _fillFrom(detail.valueOrNull!);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l10n.editKind(l10n.income) : l10n.newKind(l10n.income)),
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
              controller: _sourceController,
              decoration: InputDecoration(labelText: l10n.sourceRequired),
              textCapitalization: TextCapitalization.words,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? l10n.sourceRequired
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(labelText: l10n.amountRsRequired),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: _amountValidator,
            ),
            const SizedBox(height: 12),
            AppDateField(
              value: _incomeDate,
              onChanged: (picked) {
                if (picked != null) setState(() => _incomeDate = picked);
              },
              label: l10n.dateLabel,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: l10n.descriptionLabel),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _paymentMethodController,
              decoration: InputDecoration(labelText: l10n.paymentMethod),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _referenceController,
              decoration: InputDecoration(labelText: l10n.reference),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(labelText: l10n.notes),
              maxLines: 3,
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

  void _fillFrom(IncomeEntity income) {
    _sourceController.text = income.source;
    _amountController.text = (income.amount / 100).toStringAsFixed(2);
    _incomeDate = income.incomeDate;
    _descriptionController.text = income.description ?? '';
    _paymentMethodController.text = income.paymentMethod ?? '';
    _referenceController.text = income.reference ?? '';
    _notesController.text = income.notes ?? '';
  }

  String? _amountValidator(String? value) {
    final l10n = AppLocalizations.of(context);
    final text = value?.trim() ?? '';
    if (text.isEmpty) return l10n.amountRequired;
    final parsed = double.tryParse(text);
    if (parsed == null) return l10n.amountInvalidFull;
    if (parsed <= 0) return l10n.amountMustBePositive;
    return null;
  }


  int _paisa(String text) {
    final rupees = double.tryParse(text.trim()) ?? 0;
    return (rupees * 100).round();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final queue = ref.read(offlineQueueProvider);
    final queuedBefore = queue.queuedCount;
    try {
      final repository = ref.read(incomeRepositoryProvider);
      final source = _sourceController.text.trim();
      final amount = _paisa(_amountController.text);
      final description = _descriptionController.text.trim();
      final paymentMethod = _paymentMethodController.text.trim();
      final reference = _referenceController.text.trim();
      final notes = _notesController.text.trim();

      if (_isEdit) {
        await repository.updateIncome(
          widget.incomeId!,
          source: source,
          amount: amount,
          incomeDate: _incomeDate,
          description: description.isEmpty ? null : description,
          paymentMethod: paymentMethod.isEmpty ? null : paymentMethod,
          reference: reference.isEmpty ? null : reference,
          notes: notes.isEmpty ? null : notes,
        );
      } else {
        await repository.createIncome(
          source: source,
          amount: amount,
          incomeDate: _incomeDate,
          description: description.isEmpty ? null : description,
          paymentMethod: paymentMethod.isEmpty ? null : paymentMethod,
          reference: reference.isEmpty ? null : reference,
          notes: notes.isEmpty ? null : notes,
        );
      }

      refreshIncome(ref);
      if (mounted) {
        context.go('/income');
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
        title: Text(l10n.deleteIncomeQuestion),
        content: Text(l10n.incomeDeleteNote),
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
      await ref.read(incomeRepositoryProvider).deleteIncome(widget.incomeId!);
      refreshIncome(ref);
      if (mounted) {
        context.go('/income');
        if (queue.queuedCount > queuedBefore) {
          showQueuedOfflineSnackBar(context, l10n.savedOffline);
        } else {
          showInfoSnackBar(context, l10n.deleted);
        }
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, '$e');
    }
  }

}
