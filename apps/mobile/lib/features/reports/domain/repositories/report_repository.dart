import 'dart:typed_data';

import '../entities/report_entities.dart';

/// Reports repository contract. All calls are scoped to the active business
/// on the server; date ranges are inclusive.
abstract class ReportRepository {
  Future<SalesReportEntity> getSalesReport({
    required DateTime from,
    required DateTime to,
    String groupBy = 'day',
    int top = 10,
  });

  Future<PurchaseReportEntity> getPurchaseReport({
    required DateTime from,
    required DateTime to,
    String groupBy = 'day',
    int top = 10,
  });

  Future<ProfitLossEntity> getProfitLoss({
    required DateTime from,
    required DateTime to,
  });

  Future<ExpenseReportEntity> getExpenseReport({
    required DateTime from,
    required DateTime to,
    String groupBy = 'day',
  });

  Future<IncomeReportEntity> getIncomeReport({
    required DateTime from,
    required DateTime to,
    String groupBy = 'day',
  });

  Future<StockReportEntity> getStockReport({
    bool lowStockOnly = false,
    String? search,
  });

  Future<ReceivablePayableReportEntity> getReceivablePayable();

  /// Downloads a report as a UTF-8 (BOM-prefixed) CSV.
  Future<Uint8List> downloadCsv({
    required String type,
    required DateTime from,
    required DateTime to,
  });
}
