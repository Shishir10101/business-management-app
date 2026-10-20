/// Reports domain entities. Pure Dart, no serialization.
/// All money is integer paisa; quantity is the only decimal.
library;

import '../../../dashboard/domain/entities/dashboard_entity.dart';

// The dashboard entities are shared by the dashboard and every report, so they
// are re-exported here to keep a single import for report consumers.
export '../../../dashboard/domain/entities/dashboard_entity.dart';

/// A category/source breakdown line (expenses by category, income by source).
class CategoryAmountEntity {
  final String category;
  final int amount;
  final int count;

  const CategoryAmountEntity({
    required this.category,
    this.amount = 0,
    this.count = 0,
  });
}

/// A selected reporting window (inclusive AD dates).
class ReportRange {
  final DateTime from;
  final DateTime to;

  const ReportRange({required this.from, required this.to});

  /// The current calendar month up to today (mirrors the server default).
  factory ReportRange.currentMonth() {
    final now = DateTime.now();
    return ReportRange(
      from: DateTime(now.year, now.month, 1),
      to: DateTime(now.year, now.month, now.day),
    );
  }
}

/// GET /reports/sales.
class SalesReportEntity {
  final DateTime dateFrom;
  final DateTime dateTo;
  final String groupBy;
  final AmountSummaryEntity totals;
  final List<TrendPointEntity> series;
  final List<TopItemEntity> topProducts;
  final List<TopItemEntity> topCustomers;

  const SalesReportEntity({
    required this.dateFrom,
    required this.dateTo,
    this.groupBy = 'day',
    this.totals = const AmountSummaryEntity(),
    this.series = const [],
    this.topProducts = const [],
    this.topCustomers = const [],
  });
}

/// GET /reports/purchases.
class PurchaseReportEntity {
  final DateTime dateFrom;
  final DateTime dateTo;
  final String groupBy;
  final AmountSummaryEntity totals;
  final List<TrendPointEntity> series;
  final List<TopItemEntity> topSuppliers;

  const PurchaseReportEntity({
    required this.dateFrom,
    required this.dateTo,
    this.groupBy = 'day',
    this.totals = const AmountSummaryEntity(),
    this.series = const [],
    this.topSuppliers = const [],
  });
}

/// GET /reports/expenses.
class ExpenseReportEntity {
  final DateTime dateFrom;
  final DateTime dateTo;
  final String groupBy;
  final int total;
  final int count;
  final List<CategoryAmountEntity> byCategory;
  final List<TrendPointEntity> series;

  const ExpenseReportEntity({
    required this.dateFrom,
    required this.dateTo,
    this.groupBy = 'day',
    this.total = 0,
    this.count = 0,
    this.byCategory = const [],
    this.series = const [],
  });
}

/// GET /reports/income.
class IncomeReportEntity {
  final DateTime dateFrom;
  final DateTime dateTo;
  final String groupBy;
  final int total;
  final int count;
  final List<CategoryAmountEntity> bySource;
  final List<TrendPointEntity> series;

  const IncomeReportEntity({
    required this.dateFrom,
    required this.dateTo,
    this.groupBy = 'day',
    this.total = 0,
    this.count = 0,
    this.bySource = const [],
    this.series = const [],
  });
}

/// GET /reports/profit-loss.
class ProfitLossEntity {
  final DateTime dateFrom;
  final DateTime dateTo;
  final int revenue;
  final int costOfGoods;
  final int grossProfit;
  final int otherIncome;
  final int expenses;
  final int netProfit;
  final int salesTaxCollected;
  final List<CategoryAmountEntity> expensesByCategory;

  const ProfitLossEntity({
    required this.dateFrom,
    required this.dateTo,
    this.revenue = 0,
    this.costOfGoods = 0,
    this.grossProfit = 0,
    this.otherIncome = 0,
    this.expenses = 0,
    this.netProfit = 0,
    this.salesTaxCollected = 0,
    this.expensesByCategory = const [],
  });
}

/// One product line of the stock valuation report.
class StockRowEntity {
  final int productId;
  final String name;
  final String? categoryName;
  final String? unitShortName;
  final double quantity;
  final int costPrice;
  final int sellingPrice;
  final int costValue;
  final int retailValue;
  final bool isLowStock;

  const StockRowEntity({
    required this.productId,
    required this.name,
    this.categoryName,
    this.unitShortName,
    this.quantity = 0,
    this.costPrice = 0,
    this.sellingPrice = 0,
    this.costValue = 0,
    this.retailValue = 0,
    this.isLowStock = false,
  });
}

/// GET /reports/stock.
class StockReportEntity {
  final int totalCostValue;
  final int totalRetailValue;
  final int potentialMargin;
  final int productCount;
  final int lowStockCount;
  final List<StockRowEntity> items;

  const StockReportEntity({
    this.totalCostValue = 0,
    this.totalRetailValue = 0,
    this.potentialMargin = 0,
    this.productCount = 0,
    this.lowStockCount = 0,
    this.items = const [],
  });
}

/// A party with an outstanding balance (receivable or payable).
class OutstandingPartyEntity {
  final int partyId;
  final String name;
  final String? phoneNumber;
  final int balance;
  final int openDocuments;

  const OutstandingPartyEntity({
    required this.partyId,
    required this.name,
    this.phoneNumber,
    this.balance = 0,
    this.openDocuments = 0,
  });
}

/// GET /reports/receivable-payable.
class ReceivablePayableReportEntity {
  final int totalReceivable;
  final int totalPayable;
  final int customerAdvances;
  final int supplierAdvances;
  final List<OutstandingPartyEntity> receivables;
  final List<OutstandingPartyEntity> payables;

  const ReceivablePayableReportEntity({
    this.totalReceivable = 0,
    this.totalPayable = 0,
    this.customerAdvances = 0,
    this.supplierAdvances = 0,
    this.receivables = const [],
    this.payables = const [],
  });
}
