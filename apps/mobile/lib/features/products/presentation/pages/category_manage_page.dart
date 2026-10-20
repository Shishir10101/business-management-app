import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/khata_snackbars.dart';
import '../../domain/entities/product_entity.dart';
import '../providers/product_providers.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../../../l10n/app_localizations.dart';

/// Manage product categories: list, add (dialog), rename/delete.
/// Categories with active sub-categories cannot be deleted (server 422).
class CategoryManagePage extends ConsumerWidget {
  const CategoryManagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);


    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.categories)),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _PageError(
          message: l10n.couldNotLoad('$error'),
          onRetry: () => ref.invalidate(categoriesProvider),
        ),
        data: (categories) {
          if (categories.isEmpty) {
            return Center(child: Text(l10n.categoriesNoCategories));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(categoriesProvider),
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: Text(category.name),
                    subtitle: Text(
                      '${category.productCount} product(s)'
                      '${category.parentName != null ? ' • in ${category.parentName}' : ''}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        switch (value) {
                          case 'edit':
                            await _editCategory(context, ref, category);
                            break;
                          case 'delete':
                            await _deleteCategory(context, ref, category.id);
                            break;
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
        onPressed: () => _editCategory(context, ref, null),
        icon: const Icon(Icons.add),
        label: Text(l10n.addCategory),
      ),
    );
  }

  Future<void> _editCategory(
    BuildContext context,
    WidgetRef ref,
    CategoryEntity? current,
  ) async {
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController(text: current?.name ?? '');
    final descriptionController =
        TextEditingController(text: current?.description ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(current == null
            ? l10n.newKind(l10n.category)
            : l10n.editKind(l10n.category)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: l10n.nameRequired),
              autofocus: true,
            ),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: l10n.descriptionLabel),
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
    if (result != true || nameController.text.trim().isEmpty) return;
    try {
      final repository = ref.read(productRepositoryProvider);
      if (current == null) {
        await repository.createCategory(
          name: nameController.text.trim(),
          description: descriptionController.text.trim().isEmpty
              ? null
              : descriptionController.text.trim(),
        );
      } else {
        await repository.updateCategory(
          current.id,
          name: nameController.text.trim(),
          description: descriptionController.text.trim().isEmpty
              ? null
              : descriptionController.text.trim(),
          parentId: current.parentId,
          isActive: current.isActive,
        );
      }
      refreshCatalog(ref);
      if (context.mounted) showInfoSnackBar(context, l10n.categorySaved);
    } catch (e) {
      if (context.mounted) showErrorSnackBar(context, '$e');
    }
  }

  Future<void> _deleteCategory(
      BuildContext context, WidgetRef ref, int id) async {
        final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteCategoryQuestion),
        content: Text(
            l10n.categoryDeleteNote),
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
      await ref.read(productRepositoryProvider).deleteCategory(id);
      refreshCatalog(ref);
      if (context.mounted) showInfoSnackBar(context, l10n.categoryDeleted);
    } catch (e) {
      if (context.mounted) showErrorSnackBar(context, '$e');
    }
  }
}

class _PageError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _PageError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);


    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(l10n.couldNotLoad('$message'), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: Text(l10n.retry)),
          ],
        ),
      ),
    );
  }
}
