import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/format_utils.dart';
import '../providers/report_providers.dart';
import '../widgets/report_charts.dart';
import '../widgets/report_range_bar.dart';
import '../widgets/report_widgets.dart';
import '../../../../l10n/app_localizations.dart';

/// Profit & loss statement for the selected range.
class ProfitLossPage extends ConsumerWidget {
  const ProfitLossPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final report = ref.watch(profitLossProvider);
    final range = ref.watch(reportRangeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profitAndLoss)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'pl-export',
        onPressed: () => downloadAndShareCsv(
          context,
          ref,
          type: 'profit-loss',
          from: range.from,
          to: range.to,
        ),
        icon: const Icon(Icons.download_outlined),
        label: Text(l10n.exportCsv),
      ),
      body: report.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ReportErrorView(
          message: l10n.couldNotLoadX(l10n.profitAndLoss, '$error'),
          onRetry: () => refreshReports(ref),
        ),
        data: (pl) => RefreshIndicator(
          onRefresh: () async => refreshReports(ref),
          child: ListView(
            children: [
              const ReportRangeBar(showGrouping: false),
              ReportCard(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  children: [
                    _StatementLine(l10n.revenue, pl.revenue),
                    _StatementLine(l10n.costOfGoodsSold, -pl.costOfGoods),
                    const Divider(),
                    _StatementLine(l10n.grossProfit, pl.grossProfit, bold: true),
                    _StatementLine(l10n.otherIncome, pl.otherIncome),
                    _StatementLine('Expenses', -pl.expenses),
                    const Divider(),
                    _StatementLine(l10n.netProfit, pl.netProfit, bold: true),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${l10n.revenueExcludesVat} '
                            '${l10n.taxCollectedInPeriod} '
                            '${formatPaisa(pl.salesTaxCollected)}.',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ReportSectionTitle(title: l10n.expensesByCategory),
              ReportCard(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: ReportPieChart(
                  slices: [
                    for (var i = 0; i < pl.expensesByCategory.length; i++)
                      PieSlice(
                        label: pl.expensesByCategory[i].category,
                        paisa: pl.expensesByCategory[i].amount,
                        value: pl.expensesByCategory[i].amount.toDouble(),
                        color: reportColorAt(i),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 88),
            ],
          ),
        ),
      ),
    );
  }
}

/// One line of the profit & loss statement, e.g. "Revenue  Rs 12,500.00".
class _StatementLine extends StatelessWidget {
  final String label;
  final int paisa;
  final bool bold;

  const _StatementLine(this.label, this.paisa, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(formatPaisa(paisa), style: style),
        ],
      ),
    );
  }
}
