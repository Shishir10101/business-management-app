import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/format_utils.dart';
import '../providers/report_providers.dart';
import '../widgets/report_charts.dart';
import '../widgets/report_range_bar.dart';
import '../widgets/report_widgets.dart';
import '../../../../l10n/app_localizations.dart';

/// Expense report: total, a trend line and a category breakdown pie.
class ExpenseReportPage extends ConsumerWidget {
  const ExpenseReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final report = ref.watch(expenseReportProvider);
    final range = ref.watch(reportRangeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.expenses)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'expense-export',
        onPressed: () => downloadAndShareCsv(
          context,
          ref,
          type: 'expenses',
          from: range.from,
          to: range.to,
        ),
        icon: const Icon(Icons.download_outlined),
        label: Text(l10n.exportCsv),
      ),
      body: report.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ReportErrorView(
          message: l10n.couldNotLoadX(l10n.expenseReport, '$error'),
          onRetry: () => refreshReports(ref),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () async => refreshReports(ref),
          child: ListView(
            children: [
              const ReportRangeBar(),
              ReportTotalsGrid(totals: [
                ReportTotal('Total', formatPaisa(data.total)),
                ReportTotal(l10n.entries, '${data.count}'),
                ReportTotal(l10n.categories, '${data.byCategory.length}'),
                ReportTotal(
                    l10n.average,
                    data.count == 0
                        ? formatPaisa(0)
                        : formatPaisa((data.total / data.count).round())),
              ]),
              ReportSectionTitle(title: l10n.expenseTrend),
              ReportCard(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: ReportLineChart(
                  valuesRupees:
                      data.series.map((p) => p.expenses / 100).toList(),
                ),
              ),
              ReportSectionTitle(title: l10n.byCategory),
              ReportCard(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: ReportPieChart(
                  slices: [
                    for (var i = 0; i < data.byCategory.length; i++)
                      PieSlice(
                        label: data.byCategory[i].category,
                        paisa: data.byCategory[i].amount,
                        value: data.byCategory[i].amount.toDouble(),
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
