import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/nepali_date_utils.dart';
import '../../domain/entities/purchase_entity.dart';
import '../providers/purchase_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/router/nav.dart';

/// Purchases list: search, payment-status filter, and a link to each purchase.
class PurchaseListPage extends ConsumerWidget {
  const PurchaseListPage({super.key});

  static const _statuses = <String?>[null, 'Paid', 'Partial', 'Unpaid'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final purchasesAsync = ref.watch(purchaseListProvider);
    final status = ref.watch(purchaseStatusFilterProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.purchases)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.searchBillOrSupplier,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              onChanged: (value) =>
                  ref.read(purchaseSearchProvider.notifier).state = value,
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                for (final option in _statuses)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_statusLabel(option, l10n)),
                      selected: status == option,
                      onSelected: (_) => ref
                          .read(purchaseStatusFilterProvider.notifier)
                          .state = option,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: purchasesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48),
                      const SizedBox(height: 12),
                      Text(l10n.couldNotLoadX(l10n.purchases, '$error'),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => refreshPurchases(ref),
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
              ),
              data: (purchases) {
                if (purchases.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_bag_outlined, size: 48),
                          SizedBox(height: 12),
                          Text(l10n.noPurchases),
                        ],
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => refreshPurchases(ref),
                  child: ListView.builder(
                    // Clear of the extended FAB, which otherwise covers the last row.
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: purchases.length,
                    itemBuilder: (context, index) =>
                        _PurchaseTile(purchase: purchases[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openRoute(context, '/purchases/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.newPurchase),
      ),
    );
  }
}

/// Payment-status colour, shared by the list and detail pages.
Color purchaseStatusColor(BuildContext context, String status) {
  final scheme = Theme.of(context).colorScheme;
  switch (status) {
    case 'Paid':
      return Colors.green.shade700;
    case 'Partial':
      return Colors.orange.shade800;
    default:
      return scheme.error;
  }
}

class _PurchaseTile extends StatelessWidget {
  final PurchaseEntity purchase;

  const _PurchaseTile({required this.purchase});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: purchaseStatusColor(context, purchase.paymentStatus)
              .withOpacity(0.12),
          child: Icon(
            Icons.shopping_bag_outlined,
            size: 18,
            color: purchaseStatusColor(context, purchase.paymentStatus),
          ),
        ),
        title: Text(
            '${purchase.billNumber}  •  ${purchase.supplierName ?? l10n.noSupplier}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${_date(purchase.purchaseDate)}  •  ${purchase.purchaseType}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatPaisa(purchase.totalAmount),
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              purchase.dueAmount > 0
                  ? l10n.dueAmount(formatPaisa(purchase.dueAmount))
                  : purchase.paymentStatus,
              style: theme.textTheme.labelSmall?.copyWith(
                color: purchaseStatusColor(context, purchase.paymentStatus),
              ),
            ),
          ],
        ),
        onTap: () => openRoute(context, '/purchases/${purchase.id}'),
      ),
    );
  }

  static String _date(DateTime d) =>
      formatDisplayDate(d);
}

/// Chip label for a payment-status filter option. The option itself stays a
/// wire value (it is sent to the API); only the label is localized.
String _statusLabel(String? status, AppLocalizations l10n) => switch (status) {
      'Paid' => l10n.paid,
      'Partial' => l10n.partial,
      'Unpaid' => l10n.unpaid,
      _ => l10n.all,
    };
