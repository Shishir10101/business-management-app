import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/format_utils.dart';
import '../providers/report_providers.dart';
import '../widgets/report_charts.dart';
import '../widgets/report_range_bar.dart';
import '../widgets/report_widgets.dart';
import '../../../../l10n/app_localizations.dart';

/// Sales report: totals, a daily/weekly/monthly trend chart, the best-selling
/// products and the top customers for the selected range.
class SalesReportPage extends ConsumerWidget {
  const SalesReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final report = ref.watch(salesReportProvider);
    final range = ref.watch(reportRangeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.salesReportTitle)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'sales-export',
        onPressed: () => downloadAndShareCsv(
          context,
          ref,
          type: 'sales',
          from: range.from,
          to: range.to,
        ),
        icon: const Icon(Icons.download_outlined),
        label: Text(l10n.exportCsv),
      ),
      body: report.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ReportErrorView(
          message: l10n.couldNotLoadX(l10n.salesReportTitle, '$error'),
          onRetry: () => refreshReports(ref),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () async => refreshReports(ref),
          child: ListView(
            children: [
              const ReportRangeBar(),
              ReportTotalsGrid(totals: [
                ReportTotal(l10n.sales, '${data.totals.count}'),
                ReportTotal('Total', formatPaisa(data.totals.total)),
                ReportTotal('Paid', formatPaisa(data.totals.paid)),
                ReportTotal('Due', formatPaisa(data.totals.due)),
              ]),
              ReportSectionTitle(
                  title: l10n.salesTrendScope(_scope(data.groupBy))),
              ReportCard(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: ReportLineChart(
                  valuesRupees: data.series.map((p) => p.sales / 100).toList(),
                ),
              ),
              ReportSectionTitle(title: l10n.topProducts),
              if (data.topProducts.isEmpty)
                ReportEmptyLine(message: l10n.noProductsSoldInRange)
              else ...[
                ReportCard(
                  margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: ReportBarChart(
                    valuesRupees:
                        data.topProducts.map((p) => p.amount / 100).toList(),
                  ),
                ),
                for (var i = 0; i < data.topProducts.length; i++)
                  ReportRankedTile(rank: i + 1, item: data.topProducts[i]),
              ],
              ReportSectionTitle(title: l10n.topCustomers),
              if (data.topCustomers.isEmpty)
                ReportEmptyLine(
                    message: l10n.noSalesToCustomersInRange)
              else
                for (var i = 0; i < data.topCustomers.length; i++)
                  ReportRankedTile(rank: i + 1, item: data.topCustomers[i]),
              const SizedBox(height: 88),
            ],
          ),
        ),
      ),
    );
  }
}

/// Human label for the API's grouping value.
String _scope(String groupBy) {
  switch (groupBy) {
    case 'week':
      return 'weekly';
    case 'month':
      return 'monthly';
    default:
      return 'daily';
  }
}
