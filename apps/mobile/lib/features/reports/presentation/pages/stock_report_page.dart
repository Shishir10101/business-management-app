import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/format_utils.dart';
import '../providers/report_providers.dart';
import '../widgets/report_range_bar.dart';
import '../widgets/report_widgets.dart';
import '../../../../l10n/app_localizations.dart';

/// Stock valuation: cost and retail value of stock on hand, with a low-stock
/// filter and a product search.
class StockReportPage extends ConsumerWidget {
  const StockReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final report = ref.watch(stockReportProvider);
    final lowOnly = ref.watch(stockLowStockOnlyProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.stockValuation)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'stock-export',
        onPressed: () {
          final range = ref.read(reportRangeProvider);
          downloadAndShareCsv(
            context,
            ref,
            type: 'stock',
            from: range.from,
            to: range.to,
          );
        },
        icon: const Icon(Icons.download_outlined),
        label: Text(l10n.exportCsv),
      ),
      body: report.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ReportErrorView(
          message: l10n.couldNotLoadX(l10n.stockReportTitle, '$error'),
          onRetry: () => refreshReports(ref),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () async => refreshReports(ref),
          child: ListView(
            children: [
              ReportTotalsGrid(totals: [
                ReportTotal(l10n.costValue, formatPaisa(data.totalCostValue)),
                ReportTotal(l10n.retailValueReport, formatPaisa(data.totalRetailValue)),
                ReportTotal(
                    l10n.potentialMargin, formatPaisa(data.potentialMargin)),
                ReportTotal(l10n.lowStockAlert, '${data.lowStockCount}'),
              ]),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: l10n.searchProducts,
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        isDense: true,
                      ),
                      onChanged: (value) =>
                          ref.read(stockSearchProvider.notifier).state = value,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.lowStockOnly),
                      value: lowOnly,
                      onChanged: (value) => ref
                          .read(stockLowStockOnlyProvider.notifier)
                          .state = value,
                    ),
                  ],
                ),
              ),
              ReportSectionTitle(
                title: l10n.productsCount(data.items.length),
              ),
              if (data.items.isEmpty)
                ReportEmptyLine(message: l10n.noProductsMatchFilter)
              else
                for (final item in data.items)
                  Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      title: Text(item.name),
                      subtitle: Text(
                        [
                          if (item.categoryName != null) item.categoryName!,
                          '${formatQuantity(item.quantity)}'
                              '${item.unitShortName != null ? ' ${item.unitShortName}' : ''}',
                          'cost ${formatPaisa(item.costPrice)}',
                        ].join(' · '),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(formatPaisa(item.costValue),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          Text(
                            l10n.retailValue(formatPaisa(item.retailValue)),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                      isThreeLine: false,
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
