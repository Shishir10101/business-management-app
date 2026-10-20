import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/khata_snackbars.dart';
import '../../domain/entities/product_entity.dart';
import '../providers/product_providers.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../../../l10n/app_localizations.dart';

/// Manage units of measure: list, add (dialog), rename, delete.
/// Unit names are unique per business (duplicate names get a 409 error).
class UnitManagePage extends ConsumerWidget {
  const UnitManagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);


    final unitsAsync = ref.watch(unitsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.units)),
      body: unitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Text(l10n.couldNotLoad('$error'),
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => ref.invalidate(unitsProvider),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
        data: (units) {
          if (units.isEmpty) {
            return Center(child: Text(l10n.unitsNoUnits));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(unitsProvider),
            child: ListView.builder(
              itemCount: units.length,
              itemBuilder: (context, index) {
                final unit = units[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        unit.shortName,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                    title: Text(unit.name),
                    subtitle: Text(l10n.productsCount(unit.productCount)),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'delete') {
                          await _deleteUnit(context, ref, unit.id);
                        } else if (value == 'edit') {
                          await _editUnit(context, ref, unit);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                        PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editUnit(context, ref, null),
        icon: const Icon(Icons.add),
        label: Text(l10n.addUnit),
      ),
    );
  }

  Future<void> _editUnit(
    BuildContext context,
    WidgetRef ref,
    UnitEntity? current,
  ) async {
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController(text: current?.name ?? '');
    final shortController =
        TextEditingController(text: current?.shortName ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(current == null
            ? l10n.newKind(l10n.unit)
            : l10n.editKind(l10n.unit)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration:
                  InputDecoration(labelText: l10n.unitNameHint),
              autofocus: true,
            ),
            TextField(
              controller: shortController,
              decoration:
                  InputDecoration(labelText: l10n.unitShortHint),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    final name = nameController.text.trim();
    final shortName = shortController.text.trim();
    if (result != true || name.isEmpty || shortName.isEmpty) return;
    try {
      final repository = ref.read(productRepositoryProvider);
      if (current == null) {
        await repository.createUnit(name: name, shortName: shortName);
      } else {
        await repository.updateUnit(
          current.id,
          name: name,
          shortName: shortName,
        );
      }
      refreshCatalog(ref);
      if (context.mounted) showInfoSnackBar(context, l10n.unitSaved);
    } catch (e) {
      if (context.mounted) showErrorSnackBar(context, '$e');
    }
  }

  Future<void> _deleteUnit(BuildContext context, WidgetRef ref, int id) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteUnitQuestion),
        content: Text(
            l10n.unitDeleteNote),
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
      await ref.read(productRepositoryProvider).deleteUnit(id);
      refreshCatalog(ref);
      if (context.mounted) showInfoSnackBar(context, l10n.unitDeleted);
    } catch (e) {
      if (context.mounted) showErrorSnackBar(context, '$e');
    }
  }
}
