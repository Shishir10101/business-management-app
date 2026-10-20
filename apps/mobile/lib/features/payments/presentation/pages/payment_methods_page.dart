import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/khata_snackbars.dart';
import '../../data/repositories/payment_repository_impl.dart';
import '../../domain/entities/payment_entity.dart';
import '../providers/payment_providers.dart';
import '../../../../l10n/app_localizations.dart';

/// Manage payment methods (cash, eSewa, bank transfer, ...): list, add
/// (dialog), edit and delete. At least one method must remain.
class PaymentMethodsPage extends ConsumerWidget {
  const PaymentMethodsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);


    final methodsAsync = ref.watch(paymentMethodsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.paymentMethods)),
      body: methodsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Text(l10n.couldNotLoadX(l10n.paymentMethods, '$error'),
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => refreshPayments(ref),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
        data: (methods) {
          if (methods.isEmpty) {
            return Center(child: Text(l10n.noPaymentMethodsYet));
          }
          return RefreshIndicator(
            onRefresh: () async => refreshPayments(ref),
            child: ListView.builder(
              itemCount: methods.length,
              itemBuilder: (context, index) {
                final method = methods[index];
                return _MethodTile(
                  method: method,
                  onEdit: () => _editMethod(context, ref, method),
                  onDelete: () => _deleteMethod(context, ref, method),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editMethod(context, ref, null),
        icon: const Icon(Icons.add),
        label: Text(l10n.addPaymentMethod),
      ),
    );
  }

  Future<void> _editMethod(
    BuildContext context,
    WidgetRef ref,
    PaymentMethodEntity? current,
  ) async {
    final l10n = AppLocalizations.of(context);
    final draft = await showDialog<_MethodDraft>(
      context: context,
      builder: (_) => _MethodDialog(current: current),
    );
    if (draft == null || draft.name.isEmpty) return;

    try {
      final repository = ref.read(paymentRepositoryProvider);
      if (current == null) {
        await repository.createMethod(
          name: draft.name,
          code: draft.code,
          description: draft.description,
          isDefault: draft.isDefault,
        );
      } else {
        await repository.updateMethod(
          current.id,
          name: draft.name,
          code: draft.code,
          description: draft.description,
          isActive: draft.isActive,
          isDefault: draft.isDefault,
        );
      }
      refreshPayments(ref);
      if (context.mounted) showInfoSnackBar(context, l10n.methodSaved);
    } catch (e) {
      if (context.mounted) showErrorSnackBar(context, '$e');
    }
  }

  Future<void> _deleteMethod(
    BuildContext context,
    WidgetRef ref,
    PaymentMethodEntity method,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteMethodQuestion),
        content: Text(
            '${l10n.methodChangeNote} ${l10n.atLeastOneMethodMustRemain}'),
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
      await ref.read(paymentRepositoryProvider).deleteMethod(method.id);
      refreshPayments(ref);
      if (context.mounted) showInfoSnackBar(context, l10n.methodDeleted);
    } catch (e) {
      if (context.mounted) showErrorSnackBar(context, '$e');
    }
  }
}

/// One payment method row: name, code, a default chip and a delete action.
class _MethodTile extends StatelessWidget {
  final PaymentMethodEntity method;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MethodTile({
    required this.method,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);


    final subtitle = [
      if (method.code.isNotEmpty) method.code,
      if (!method.isActive) 'Inactive',
    ].join('  •  ');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Opacity(
        opacity: method.isActive ? 1 : 0.5,
        child: ListTile(
          leading: const Icon(Icons.account_balance_wallet_outlined),
          title: Text(method.name),
          subtitle: subtitle.isEmpty ? null : Text(subtitle),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (method.isDefault)
                Chip(
                  label: Text(l10n.defaultLabel, style: TextStyle(fontSize: 12)),
                  visualDensity: VisualDensity.compact,
                ),
              IconButton(
                tooltip: l10n.delete,
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
              ),
            ],
          ),
          onTap: onEdit,
        ),
      ),
    );
  }
}

/// Values returned by the method dialog.
class _MethodDraft {
  final String name;
  final String? code;
  final String? description;
  final bool isActive;
  final bool isDefault;

  const _MethodDraft({
    required this.name,
    this.code,
    this.description,
    this.isActive = true,
    this.isDefault = false,
  });
}

/// Add/edit dialog for a payment method. Pops a [_MethodDraft] on save.
class _MethodDialog extends StatefulWidget {
  final PaymentMethodEntity? current;

  const _MethodDialog({this.current});

  @override
  State<_MethodDialog> createState() => _MethodDialogState();
}

class _MethodDialogState extends State<_MethodDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _descriptionController;
  late bool _isActive;
  late bool _isDefault;

  @override
  void initState() {
    super.initState();
    final current = widget.current;
    _nameController = TextEditingController(text: current?.name ?? '');
    _codeController = TextEditingController(text: current?.code ?? '');
    _descriptionController =
        TextEditingController(text: current?.description ?? '');
    _isActive = current?.isActive ?? true;
    _isDefault = current?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);


    final isEdit = widget.current != null;

    return AlertDialog(
      title: Text(isEdit ? l10n.editKind(l10n.paymentMethod) : l10n.newMethod),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.nameRequired),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(labelText: l10n.code),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: l10n.descriptionLabel),
            ),
            if (isEdit)
              SwitchListTile(
                title: Text(l10n.active),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
                contentPadding: EdgeInsets.zero,
              ),
            SwitchListTile(
              title: Text(l10n.setAsDefault),
              value: _isDefault,
              onChanged: (value) => setState(() => _isDefault = value),
              contentPadding: EdgeInsets.zero,
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
            final name = _nameController.text.trim();
            if (name.isEmpty) return;
            final code = _codeController.text.trim();
            final description = _descriptionController.text.trim();
            Navigator.of(context).pop(_MethodDraft(
              name: name,
              code: code.isEmpty ? null : code,
              description: description.isEmpty ? null : description,
              isActive: _isActive,
              isDefault: _isDefault,
            ));
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
