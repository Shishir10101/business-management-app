import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/nav.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/nepali_date_utils.dart';
import '../../../business/presentation/providers/business_providers.dart';
import '../../../parties/presentation/providers/party_providers.dart';
import '../../../products/presentation/providers/product_providers.dart';
import '../../../sales/domain/entities/sale_entity.dart';
import '../../../sales/presentation/providers/sale_providers.dart';
import '../../../sync/presentation/providers/sync_providers.dart';
import '../../../sync/presentation/widgets/offline_banner.dart';
import '../../domain/entities/dashboard_entity.dart';
import '../providers/dashboard_providers.dart';
import '../../../../l10n/app_localizations.dart';

/// Home.
///
/// Ordered by what a shopkeeper opens the app to find, not by what the data
/// model has: today's takings, the four actions they perform all day, anything
/// that needs attention, then the trend and the last few transactions. The
/// twenty-destination tile grid that used to live here moved to **More** — on
/// a 6" phone its last tile was four scrolls down, and none of it was ever
/// "where am I".
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    // The router redirect handles fresh navigations, but if the business list
    // finishes loading AFTER the user already landed here, we still need to
    // send users without any business through the setup flow.
    ref.listenManual(myBusinessesProvider, (previous, next) {
      final businesses = next.valueOrNull;
      if (!next.isLoading && businesses != null && businesses.isEmpty) {
        context.go('/business/setup');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final businesses = ref.watch(myBusinessesProvider);
    final active = ref.watch(activeBusinessProvider);
    final dashboard = ref.watch(dashboardProvider);
    final data = dashboard.valueOrNull;

    final loaded = businesses.valueOrNull;
    final businessName = active?.name ??
        ((loaded != null && loaded.isNotEmpty) ? loaded.first.name : null) ??
        l10n.noBusiness;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              businessName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              // Today, in whichever calendar the user reads (ties into the
              // AD/BS setting; the business name is already the title above).
              formatDisplayDate(DateTime.now()),
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l10n.notifications,
            onPressed: () => openRoute(context, '/notifications'),
            icon: const Icon(Icons.notifications_none),
          ),
          IconButton(
            tooltip: l10n.profile,
            onPressed: () => openRoute(context, '/profile'),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      // The offline banner sits above the scroll (it renders nothing while
      // online, so it is safe to mount unconditionally) so a full-width band
      // is not inset by the ListView's padding.
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const OfflineBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                refreshDashboard(ref);
                ref.invalidate(recentSalesProvider);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _TodayHero(data: data, loading: dashboard.isLoading),
                  const SizedBox(height: 14),
                  // The four things a shop does all day, one tap from opening
                  // the app — the pattern Khatabook/Vyapar lead with, instead
                  // of making the user find the right tile first.
                  const _QuickActions(),
                  const SizedBox(height: 14),
                  _AttentionStrip(data: data),
                  _BalancePair(data: data),
                  // A brand-new shop has no trend and no activity to show; it
                  // gets the three steps that make the app useful instead of
                  // three empty charts.
                  if (data != null && data.productCount == 0)
                    const _GettingStarted()
                  else ...[
                    _SalesTrendCard(trend: data?.trend ?? const []),
                    const SizedBox(height: 14),
                    const _RecentActivity(),
                    const SizedBox(height: 14),
                    _TopProducts(items: data?.topProducts ?? const []),
                  ],
                  if (dashboard.hasError) ...[
                    const SizedBox(height: 12),
                    _InlineError(
                      message: l10n.dashboardUnavailable,
                      onRetry: () => refreshDashboard(ref),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Today's takings, promoted to the one number the shop opens the app for.
///
/// The four stat cards that used to open the screen gave "To collect" the same
/// weight as "Sales today", so the thing a shopkeeper checks twenty times a day
/// was one of four equal boxes. Here it is a single high-contrast card; the
/// balances it displaced sit below it in their own pair.
class _TodayHero extends StatelessWidget {
  final DashboardEntity? data;
  final bool loading;

  const _TodayHero({required this.data, required this.loading});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Fixed brand gradient rather than the seeded primary: in dark mode the
    // primary is a pale mint and white text on it is unreadable.
    const top = Color(0xFF0E7C59);
    const bottom = Color(0xFF08543C);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [top, bottom],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: bottom.withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront_outlined,
                  size: 15, color: Colors.white70),
              const SizedBox(width: 6),
              Text(
                l10n.todaysSales,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                formatDisplayDate(DateTime.now()),
                style: const TextStyle(fontSize: 11, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (loading && data == null)
            const _HeroSkeleton()
          else
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatPaisa(data?.todaySales.total ?? 0),
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  fontFeatures: AppTheme.tabularFigures,
                ),
              ),
            ),
          const SizedBox(height: 14),
          Container(height: 1, color: Colors.white.withOpacity(0.16)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  label: l10n.netProfit,
                  value: formatPaisa(data?.todayNetProfit ?? 0),
                ),
              ),
              Container(width: 1, height: 26, color: Colors.white24),
              const SizedBox(width: 14),
              Expanded(
                child: _HeroStat(
                  // The count alone under the "Sales" label: "Sales / 0 sales"
                  // read as a stutter in Nepali ("बिक्री / ० बिक्री").
                  label: l10n.sales,
                  value: formatCount(data?.todaySales.count ?? 0),
                ),
              ),
            ],
          ),
          if (data != null && data!.monthSales.total > 0) ...[
            const SizedBox(height: 10),
            Text(
              l10n.monthToDate(formatPaisa(data!.monthSales.total)),
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.66),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;

  const _HeroStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white60),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFeatures: AppTheme.tabularFigures,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

/// "3 items low on stock · 2 waiting to sync" — the two things that are wrong
/// right now, on the screen the user already opens. Renders nothing when
/// there is nothing to say, so a healthy shop sees no red.
class _AttentionStrip extends ConsumerWidget {
  final DashboardEntity? data;

  const _AttentionStrip({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final money = context.money;
    final pending = ref.watch(pendingCountProvider);
    final lowStock = data?.lowStockCount ?? 0;

    if (lowStock == 0 && pending == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (lowStock > 0)
            _AlertPill(
              icon: Icons.inventory_2_outlined,
              label: l10n.lowStockCountLabel(lowStock),
              color: money.warning,
              background: money.warningTint,
              onTap: () => openRoute(context, '/inventory'),
            ),
          if (pending > 0)
            _AlertPill(
              icon: Icons.cloud_upload_outlined,
              label: l10n.pendingWritesCount(pending),
              color: money.warning,
              background: money.warningTint,
              onTap: () => openRoute(context, '/sync'),
            ),
        ],
      ),
    );
  }
}

class _AlertPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  const _AlertPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "To collect" and "To pay", side by side, in the two money colours the rest
/// of the app uses. Tapping opens the matching khata list.
class _BalancePair extends StatelessWidget {
  final DashboardEntity? data;

  const _BalancePair({required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final money = context.money;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(
            child: _BalanceCard(
              icon: Icons.call_received,
              label: l10n.toCollect,
              value: formatPaisa(data?.totalReceivable ?? 0),
              color: money.positive,
              tint: money.positiveTint,
              onTap: () => openRoute(context, '/customers'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _BalanceCard(
              icon: Icons.call_made,
              label: l10n.toPay,
              value: formatPaisa(data?.totalPayable ?? 0),
              color: money.negative,
              tint: money.negativeTint,
              onTap: () => openRoute(context, '/suppliers'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color tint;
  final VoidCallback onTap;

  const _BalanceCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.tint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: tint,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(icon, size: 14, color: color),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontFeatures: AppTheme.tabularFigures,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The four actions a shop performs every day, sized for a thumb.
///
/// Deliberately above the numbers: the figures are for reading once, the
/// buttons are for tapping all day.
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final actions = <(IconData, String, String)>[
      (Icons.add_shopping_cart, l10n.newSale, '/sales/new'),
      (Icons.receipt_long_outlined, l10n.addExpense, '/expenses/new'),
      (Icons.payments_outlined, l10n.recordPayment, '/payments/new'),
      (Icons.person_add_alt, l10n.addCustomer, '/customers/new'),
    ];

    // IntrinsicHeight + stretch makes all four tiles the height of the tallest
    // label, so "Record payment" wrapping to two lines does not leave its
    // neighbours short and vertically centred. Plain `stretch` must never be
    // used on its own here: inside a ListView the height is unbounded and the
    // row would swallow the viewport.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: _QuickAction(
                icon: actions[i].$1,
                label: actions[i].$2,
                onTap: () => openRoute(context, actions[i].$3),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardTheme.color ?? theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.dividerTheme.color ?? Colors.transparent),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// First-run guidance. An empty dashboard is indistinguishable from a broken
/// one; three steps with a live progress count is the cheapest activation fix
/// available without new backend work.
class _GettingStarted extends ConsumerWidget {
  const _GettingStarted();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final products = ref.watch(productListProvider).valueOrNull;
    final customers = ref.watch(customerListProvider).valueOrNull;

    final hasProduct = (products?.data.isNotEmpty ?? false);
    final hasCustomer = (customers?.items.isNotEmpty ?? false);
    final hasSale = (ref.watch(recentSalesProvider).valueOrNull?.isNotEmpty ?? false);

    final steps = <(String, String, bool, String)>[
      (l10n.getStartedStepProduct, l10n.products, hasProduct, '/products/new'),
      (l10n.getStartedStepCustomer, l10n.customers, hasCustomer, '/customers/new'),
      (l10n.getStartedStepSale, l10n.sales, hasSale, '/sales/new'),
    ];

    return Card(
      margin: const EdgeInsets.only(top: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.rocket_launch_outlined,
                    size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.getStartedTitle,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final step in steps)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => openRoute(context, step.$4),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Row(
                      children: [
                        Icon(
                          step.$3
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 20,
                          color: step.$3
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            step.$1,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              decoration:
                                  step.$3 ? TextDecoration.lineThrough : null,
                              color: step.$3
                                  ? theme.colorScheme.onSurfaceVariant
                                  : null,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The last few sales. This is the "what just happened" feed every khata app
/// puts on its home screen — without it the shop had to leave home and open
/// the sales list to check whether the morning's entry actually saved.
class _RecentActivity extends ConsumerWidget {
  const _RecentActivity();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final money = context.money;
    final sales = ref.watch(recentSalesProvider);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.recentActivity,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/sales'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(l10n.viewAll, style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
            sales.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(l10n.noDataYet,
                    style: theme.textTheme.bodySmall),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 4),
                    child: Text(
                      l10n.noSales,
                      style: theme.textTheme.bodySmall,
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final sale in items.take(5))
                      _SaleRow(
                        sale: sale,
                        money: money,
                        onTap: () => openRoute(context, '/sales/${sale.id}'),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SaleRow extends StatelessWidget {
  final SaleEntity sale;
  final MoneyColors money;
  final VoidCallback onTap;

  const _SaleRow({
    required this.sale,
    required this.money,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settled = sale.paymentStatus == 'Paid';
    final color = settled ? money.neutral : money.negative;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 0),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: money.positiveTint,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(Icons.receipt_long_outlined,
                  size: 16, color: money.positive),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sale.customerName ?? l10n.walkInCustomer,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '${sale.invoiceNumber} · ${formatDisplayDate(sale.saleDate)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatPaisa(sale.totalAmount),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: AppTheme.tabularFigures,
                  ),
                ),
                if (!settled)
                  Text(
                    sale.paymentStatus == 'Partial'
                        ? l10n.partial
                        : l10n.unpaid,
                    style: theme.textTheme.labelSmall?.copyWith(color: color),
                  ),
              ],
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

/// What actually sells, from the dashboard payload — no extra request.
class _TopProducts extends StatelessWidget {
  final List<TopItemEntity> items;

  const _TopProducts({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final money = context.money;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.topProducts, style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            for (var i = 0; i < items.take(3).length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        items[i].name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    Text(
                      formatPaisa(items[i].amount),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: money.neutral,
                        fontFeatures: AppTheme.tabularFigures,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _InlineError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.info_outline, size: 16, color: theme.colorScheme.error),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message, style: theme.textTheme.bodySmall),
        ),
        TextButton(
          onPressed: onRetry,
          child: Text(AppLocalizations.of(context).retry),
        ),
      ],
    );
  }
}

/// Compact 14-day sales trend line chart (y-axis in rupees).
class _SalesTrendCard extends StatelessWidget {
  final List<TrendPointEntity> trend;

  const _SalesTrendCard({required this.trend});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final theme = Theme.of(context);
    final spots = <FlSpot>[
      for (var i = 0; i < trend.length; i++)
        FlSpot(i.toDouble(), trend[i].sales / 100),
    ];

    return Card(
      margin: const EdgeInsets.only(top: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.salesTrendLast14,
                style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: trend.isEmpty
                  ? Center(
                      child:
                          Text(l10n.noDataYet, style: theme.textTheme.bodySmall),
                    )
                  : RepaintBoundary(
                      child: LineChart(
                        LineChartData(
                          minY: 0,
                          gridData: const FlGridData(
                            show: true,
                            drawVerticalLine: false,
                          ),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(),
                            rightTitles: const AxisTitles(),
                            bottomTitles: const AxisTitles(),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 44,
                                getTitlesWidget: (value, meta) => Text(
                                  _compactRupees(value),
                                  style: theme.textTheme.labelSmall,
                                ),
                              ),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              barWidth: 2,
                              color: theme.colorScheme.primary,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: theme.colorScheme.primary
                                    .withOpacity(0.12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "1200" -> "1.2k"; keeps the chart's y-axis labels narrow.
String _compactRupees(double value) {
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
  return value.toStringAsFixed(0);
}
