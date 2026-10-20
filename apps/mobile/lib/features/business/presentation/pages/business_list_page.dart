import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/business_providers.dart';
import '../../data/repositories/business_repository_impl.dart';
import '../../../../l10n/app_localizations.dart';

/// Business switcher: lists all businesses the user belongs to.
/// Tapping a business switches the active business token context and
/// navigates to the dashboard.
class BusinessListPage extends ConsumerWidget {
  const BusinessListPage({super.key});

  Future<void> _switch(BuildContext context, WidgetRef ref, int id) async {
    try {
      final repository = ref.read(businessRepositoryProvider);
      final result = await repository.switchBusiness(id);

      // Keep the active selection and business list in sync.
      final active = result.businesses?.where((b) => b.id == id).toList();
      if (active != null && active.isNotEmpty) {
        ref.read(activeBusinessProvider.notifier).state = active.first;
      }
      ref.invalidate(myBusinessesProvider);

      if (context.mounted) context.go('/');
    } catch (e) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.couldNotSwitchBusiness('$e'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final businessesAsync = ref.watch(myBusinessesProvider);
    final active = ref.watch(activeBusinessProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myBusinesses),
        actions: [
          IconButton(
            onPressed: () => context.go('/profile'),
            icon: const Icon(Icons.person_outline),
            tooltip: l10n.profile,
          ),
        ],
      ),
      body: businessesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Text(l10n.couldNotLoadX(l10n.businesses, '$error'),
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => ref.invalidate(myBusinessesProvider),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
        data: (businesses) {
          if (businesses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.storefront_outlined, size: 48),
                  const SizedBox(height: 12),
                  Text(l10n.noBusinesses),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.go('/business/setup'),
                    child: Text(l10n.createFirstBusiness),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: businesses.length + 1,
            itemBuilder: (context, index) {
              if (index == businesses.length) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/business/setup'),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.createNewBusiness),
                  ),
                );
              }

              final business = businesses[index];
              final isActive = active?.id == business.id;
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(business.name.substring(0, 1).toUpperCase()),
                  ),
                  title: Text(business.name),
                  subtitle: Text(business.role),
                  trailing: isActive
                      ? Chip(label: Text(l10n.active))
                      : const Icon(Icons.chevron_right),
                  onTap: isActive
                      ? null
                      : () => _switch(context, ref, business.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
