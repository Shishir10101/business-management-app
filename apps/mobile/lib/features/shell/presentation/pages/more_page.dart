import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../business/presentation/providers/business_providers.dart';
import '../../../parties/presentation/providers/party_providers.dart';
import '../../../sync/presentation/providers/sync_providers.dart';
import '../../../../core/router/nav.dart';

/// Everything that is not one of the four daily tabs.
///
/// The home screen used to carry all twenty destinations as a 2-column grid:
/// on a 6" phone the last tile was four scrolls down and nothing on the grid
/// was ever "current". Real khata apps (Khatabook, Vyapar, Karobar) put the
/// daily work in the tab bar and group the rest here by *what the shopkeeper
/// is trying to do*, not by data model.
class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Same fallback as the home header: `activeBusinessProvider` is null for
    // the first frame after a reload, and "No business" is a lie.
    final active = ref.watch(activeBusinessProvider);
    final loaded = ref.watch(myBusinessesProvider).valueOrNull;
    final businessName = active?.name ??
        ((loaded != null && loaded.isNotEmpty) ? loaded.first.name : null) ??
        l10n.noBusiness;
    final receivable = ref.watch(totalReceivableProvider).valueOrNull ?? 0;
    final payable = ref.watch(totalPayableProvider).valueOrNull ?? 0;
    final pending = ref.watch(pendingCountProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.more)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _BusinessHeader(
            name: businessName,
            receivable: receivable,
            payable: payable,
            onTap: () => openRoute(context, '/businesses'),
          ),
          if (pending > 0)
            _SyncNotice(count: pending, onTap: () => openRoute(context, '/sync')),
          _Section(
            title: l10n.moreSalesDocs,
            rows: [
              _Row(Icons.shopping_bag_outlined, l10n.purchases, '/purchases'),
              _Row(Icons.description_outlined, l10n.invoices, '/invoices'),
              _Row(Icons.request_quote_outlined, l10n.quotations,
                  '/quotations'),
              _Row(Icons.payments_outlined, l10n.payments, '/payments'),
              _Row(Icons.receipt_long_outlined, l10n.expenses, '/expenses'),
              _Row(Icons.savings_outlined, l10n.income, '/income'),
            ],
          ),
          _Section(
            title: l10n.moreItems,
            rows: [
              _Row(Icons.warehouse_outlined, l10n.inventory, '/inventory'),
              _Row(Icons.category_outlined, l10n.categories,
                  '/products/categories'),
              _Row(Icons.straighten_outlined, l10n.units, '/products/units'),
              _Row(Icons.local_shipping_outlined, l10n.suppliers, '/suppliers'),
            ],
          ),
          _Section(
            title: l10n.moreInsights,
            rows: [
              _Row(Icons.bar_chart_outlined, l10n.reports, '/reports'),
              _Row(Icons.alarm, l10n.categoryReminders, '/reminders'),
              _Row(Icons.notifications_none, l10n.notifications,
                  '/notifications'),
            ],
          ),
          _Section(
            title: l10n.moreTools,
            rows: [
              _Row(Icons.calculate_outlined, l10n.toolsTitle,
                  '/tools/calculators'),
              _Row(Icons.upload_file_outlined, l10n.importTile, '/import'),
              _Row(Icons.backup_outlined, l10n.categoryBackup, '/backup'),
              _Row(Icons.cloud_sync_outlined, l10n.syncTitle, '/sync'),
              _Row(Icons.lock_outline, l10n.appLock, '/settings/app-lock'),
            ],
          ),
          _Section(
            title: l10n.moreAccount,
            rows: [
              _Row(Icons.person_outline, l10n.profile, '/profile'),
              _Row(Icons.account_balance_outlined, l10n.bankAccounts,
                  '/businesses/bank-accounts'),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(
              l10n.appName,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The shop you are looking at, with its two headline balances. Switching
/// business used to be a header icon on the home screen only; a shopkeeper who
/// runs two shops looks for it in the account area.
class _BusinessHeader extends StatelessWidget {
  final String name;
  final int receivable;
  final int payable;
  final VoidCallback onTap;

  const _BusinessHeader({
    required this.name,
    required this.receivable,
    required this.payable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final money = context.money;
    final l10n = AppLocalizations.of(context);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                    child: Icon(Icons.storefront_outlined,
                        color: theme.colorScheme.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Icon(Icons.swap_horiz,
                      size: 20, color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MiniBalance(
                      label: l10n.toCollect,
                      value: formatPaisa(receivable),
                      color: money.positive,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: theme.dividerTheme.color,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MiniBalance(
                      label: l10n.toPay,
                      value: formatPaisa(payable),
                      color: money.negative,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniBalance extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniBalance({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontFeatures: AppTheme.tabularFigures,
            ),
          ),
        ),
      ],
    );
  }
}

/// A thin strip when the offline queue is waiting: the one place a user can
/// see that a sale has not reached the server yet.
class _SyncNotice extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _SyncNotice({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final money = context.money;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        color: money.warningTint,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.cloud_upload_outlined,
                    size: 18, color: money.warning),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.pendingWritesCount(count),
                    style: TextStyle(fontSize: 13, color: money.warning),
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: money.warning),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One titled card of rows.
class _Section extends StatelessWidget {
  final String title;
  final List<_Row> rows;

  const _Section({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 6),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: 56,
                    color: theme.dividerTheme.color,
                  ),
                rows[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String path;

  const _Row(this.icon, this.label, this.path);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.10),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 18, color: theme.colorScheme.primary),
      ),
      title: Text(label, style: theme.textTheme.bodyMedium),
      trailing: Icon(
        Icons.chevron_right,
        size: 18,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      dense: true,
      visualDensity: const VisualDensity(vertical: 1),
      onTap: () => openRoute(context, path),
    );
  }
}
