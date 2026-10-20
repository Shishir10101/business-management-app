import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/report_repository_impl.dart';
import '../../domain/entities/report_entities.dart';

/// The selected reporting window (defaults to the current month).
final reportRangeProvider =
    StateProvider<ReportRange>((ref) => ReportRange.currentMonth());

/// Grouping used by the time-series reports: 'day' | 'week' | 'month'.
final reportGroupByProvider = StateProvider<String>((ref) => 'day');

/// When true, the stock report shows only low-stock products.
final stockLowStockOnlyProvider = StateProvider<bool>((ref) => false);

/// Search text for the stock report.
final stockSearchProvider = StateProvider<String>((ref) => '');

/// Sales report for the selected range and grouping.
final salesReportProvider = FutureProvider<SalesReportEntity>((ref) async {
  final range = ref.watch(reportRangeProvider);
  return ref.read(reportRepositoryProvider).getSalesReport(
        from: range.from,
        to: range.to,
        groupBy: ref.watch(reportGroupByProvider),
      );
});

/// Profit & loss statement for the selected range.
final profitLossProvider = FutureProvider<ProfitLossEntity>((ref) async {
  final range = ref.watch(reportRangeProvider);
  return ref.read(reportRepositoryProvider).getProfitLoss(
        from: range.from,
        to: range.to,
      );
});

/// Expenses report for the selected range and grouping.
final expenseReportProvider = FutureProvider<ExpenseReportEntity>((ref) async {
  final range = ref.watch(reportRangeProvider);
  return ref.read(reportRepositoryProvider).getExpenseReport(
        from: range.from,
        to: range.to,
        groupBy: ref.watch(reportGroupByProvider),
      );
});

/// Income report for the selected range and grouping.
final incomeReportProvider = FutureProvider<IncomeReportEntity>((ref) async {
  final range = ref.watch(reportRangeProvider);
  return ref.read(reportRepositoryProvider).getIncomeReport(
        from: range.from,
        to: range.to,
        groupBy: ref.watch(reportGroupByProvider),
      );
});

/// Stock valuation, filtered by low-stock-only and search text.
final stockReportProvider = FutureProvider<StockReportEntity>((ref) async {
  return ref.read(reportRepositoryProvider).getStockReport(
        lowStockOnly: ref.watch(stockLowStockOnlyProvider),
        search: ref.watch(stockSearchProvider),
      );
});

/// Outstanding receivables and payables for the active business.
final receivablePayableProvider =
    FutureProvider<ReceivablePayableReportEntity>((ref) async {
  return ref.read(reportRepositoryProvider).getReceivablePayable();
});

/// Refreshes every report provider (pull-to-refresh / Retry).
void refreshReports(WidgetRef ref) {
  ref.invalidate(salesReportProvider);
  ref.invalidate(profitLossProvider);
  ref.invalidate(expenseReportProvider);
  ref.invalidate(incomeReportProvider);
  ref.invalidate(stockReportProvider);
  ref.invalidate(receivablePayableProvider);
}
