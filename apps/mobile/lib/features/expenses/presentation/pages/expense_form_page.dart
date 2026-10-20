import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/offline/offline_providers.dart';
import '../../../../core/widgets/khata_snackbars.dart';
import '../../../../core/widgets/app_date_field.dart';
import '../../domain/entities/expense_entity.dart';
import '../providers/expense_providers.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../../../l10n/app_localizations.dart';

/// Create/edit form for an expense. Money is entered in rupees and converted
/// to integer paisa before sending.
class ExpenseFormPage extends ConsumerStatefulWidget {
  final int? expenseId;

  const ExpenseFormPage({super.key, this.expenseId});

  @override
  ConsumerState<ExpenseFormPage> createState() => _ExpenseFormPageState();
}

class _ExpenseFormPageState extends ConsumerState<ExpenseFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _categoryController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _paymentMethodController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _expenseDate = DateTime.now();
  bool _saving = false;
  bool _loaded = false;

  bool get _isEdit => widget.expenseId != null;

  @override
  void dispose() {
    _categoryController.dispose();
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
      final detail = ref.watch(expenseDetailProvider(widget.expenseId!));
      loading = detail.isLoading;
      loadError = detail.error;
      if (!_loaded && detail.valueOrNull != null) {
        _loaded = true;
        _fillFrom(detail.valueOrNull!);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l10n.editKind(l10n.expense) : l10n.newKind(l10n.expense)),
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
              controller: _categoryController,
              decoration: InputDecoration(labelText: l10n.categoryRequired),
              textCapitalization: TextCapitalization.words,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? l10n.categoryRequired
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
              value: _expenseDate,
              onChanged: (picked) {
                if (picked != null) setState(() => _expenseDate = picked);
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

  void _fillFrom(ExpenseEntity expense) {
    _categoryController.text = expense.category;
    _amountController.text = (expense.amount / 100).toStringAsFixed(2);
    _expenseDate = expense.expenseDate;
    _descriptionController.text = expense.description ?? '';
    _paymentMethodController.text = expense.paymentMethod ?? '';
    _referenceController.text = expense.reference ?? '';
    _notesController.text = expense.notes ?? '';
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
      final repository = ref.read(expenseRepositoryProvider);
      final category = _categoryController.text.trim();
      final amount = _paisa(_amountController.text);
      final description = _descriptionController.text.trim();
      final paymentMethod = _paymentMethodController.text.trim();
      final reference = _referenceController.text.trim();
      final notes = _notesController.text.trim();

      if (_isEdit) {
        await repository.updateExpense(
          widget.expenseId!,
          category: category,
          amount: amount,
          expenseDate: _expenseDate,
          description: description.isEmpty ? null : description,
          paymentMethod: paymentMethod.isEmpty ? null : paymentMethod,
          reference: reference.isEmpty ? null : reference,
          notes: notes.isEmpty ? null : notes,
        );
      } else {
        await repository.createExpense(
          category: category,
          amount: amount,
          expenseDate: _expenseDate,
          description: description.isEmpty ? null : description,
          paymentMethod: paymentMethod.isEmpty ? null : paymentMethod,
          reference: reference.isEmpty ? null : reference,
          notes: notes.isEmpty ? null : notes,
        );
      }

      refreshExpenses(ref);
      if (mounted) {
        context.go('/expenses');
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
        title: Text(l10n.deleteExpenseQuestion),
        content: Text(l10n.expenseDeleteNote),
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
          .read(expenseRepositoryProvider)
          .deleteExpense(widget.expenseId!);
      refreshExpenses(ref);
      if (mounted) {
        context.go('/expenses');
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
