import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/nepali_date_utils.dart';
import '../providers/inventory_providers.dart';
import '../../../../l10n/app_localizations.dart';

/// Append-only stock movement history for one product, newest first.
class StockMovementsPage extends ConsumerWidget {
  final int productId;

  const StockMovementsPage({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final movementsAsync = ref.watch(stockMovementsProvider(productId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.stockHistory)),
      body: movementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Text(l10n.couldNotLoadX(l10n.stockMovements, '$error'),
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () =>
                      ref.invalidate(stockMovementsProvider(productId)),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
        data: (page) {
          if (page.data.isEmpty) {
            return Center(child: Text(l10n.noStockMovementsYet));
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(stockMovementsProvider(productId)),
            child: ListView.builder(
              itemCount: page.data.length,
              itemBuilder: (context, index) {
                final movement = page.data[index];
                final isCredit = movement.isCredit;
                final sign = isCredit ? '+' : '-';
                final quantityText =
                    '$sign ${formatQuantity(movement.quantity.abs())}';
                final color =
                    isCredit ? Colors.green.shade700 : theme.colorScheme.error;

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: Icon(
                      movementTypeIcon(movement.movementType),
                      color: color,
                    ),
                    title: Text(movementTypeLabel(movement.movementType, l10n)),
                    subtitle: Text(
                      [
                        _formatDate(movement.movementDate),
                        if (movement.notes != null &&
                            movement.notes!.isNotEmpty)
                          movement.notes!,
                      ].join(' • '),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          quantityText,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          l10n.balanceAfterIs(formatQuantity(movement.balanceAfter)),
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  static String _formatDate(DateTime date) =>
      formatDisplayDate(date);
}
