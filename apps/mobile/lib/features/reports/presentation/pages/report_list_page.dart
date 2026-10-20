import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/router/nav.dart';

/// Report directory: one card per report, each linking to its page.
class ReportListPage extends StatelessWidget {
  const ReportListPage({super.key});

  static const _routes = <String>[
    '/reports/sales',
    '/reports/profit-loss',
    '/reports/expenses',
    '/reports/income',
    '/reports/stock',
    '/reports/receivable-payable',
  ];

  static const _icons = <IconData>[
    Icons.show_chart_outlined,
    Icons.calculate_outlined,
    Icons.payments_outlined,
    Icons.savings_outlined,
    Icons.inventory_2_outlined,
    Icons.account_balance_wallet_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Built here rather than as `static const` members: the copy is localized,
    // so it depends on the context's locale.
    final titles = <String>[
      l10n.salesReportTitle,
      l10n.profitAndLossTitle,
      l10n.expenses,
      l10n.income,
      l10n.stockValuation,
      l10n.receivablesAndPayables,
    ];
    final subtitles = <String>[
      l10n.reportSalesBlurb,
      l10n.reportProfitLossBlurb,
      l10n.reportExpenseBlurb,
      l10n.reportIncomeBlurb,
      l10n.reportStockBlurb,
      l10n.reportReceivableBlurb,
    ];

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reports)),
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 24, top: 8),
        itemCount: _routes.length,
        itemBuilder: (context, index) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
              child: Icon(_icons[index],
                  size: 18, color: theme.colorScheme.primary),
            ),
            title: Text(titles[index]),
            subtitle: Text(subtitles[index], style: theme.textTheme.bodySmall),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => openRoute(context, _routes[index]),
          ),
        ),
      ),
    );
  }
}
