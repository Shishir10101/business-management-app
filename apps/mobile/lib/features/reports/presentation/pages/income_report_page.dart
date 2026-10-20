import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/format_utils.dart';
import '../providers/report_providers.dart';
import '../widgets/report_charts.dart';
import '../widgets/report_range_bar.dart';
import '../widgets/report_widgets.dart';
import '../../../../l10n/app_localizations.dart';

/// Income report (non-sale income): total, a trend line and a source breakdown.
class IncomeReportPage extends ConsumerWidget {
  const IncomeReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final report = ref.watch(incomeReportProvider);
    final range = ref.watch(reportRangeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.income)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'income-export',
        onPressed: () => downloadAndShareCsv(
          context,
          ref,
          type: 'income',
          from: range.from,
          to: range.to,
        ),
        icon: const Icon(Icons.download_outlined),
        label: Text(l10n.exportCsv),
      ),
      body: report.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ReportErrorView(
          message: l10n.couldNotLoadX(l10n.incomeReport, '$error'),
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
                ReportTotal(l10n.sources, '${data.bySource.length}'),
                ReportTotal(
                    l10n.average,
                    data.count == 0
                        ? formatPaisa(0)
                        : formatPaisa((data.total / data.count).round())),
              ]),
              ReportSectionTitle(title: l10n.incomeTrend),
              ReportCard(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: ReportLineChart(
                  valuesRupees: data.series.map((p) => p.income / 100).toList(),
                ),
              ),
              ReportSectionTitle(title: l10n.bySource),
              ReportCard(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: ReportPieChart(
                  slices: [
                    for (var i = 0; i < data.bySource.length; i++)
                      PieSlice(
                        label: data.bySource[i].category,
                        paisa: data.bySource[i].amount,
                        value: data.bySource[i].amount.toDouble(),
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
