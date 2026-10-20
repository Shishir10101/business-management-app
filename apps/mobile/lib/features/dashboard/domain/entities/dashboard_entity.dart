/// Dashboard domain entities. Pure Dart, no serialization.
/// All money is integer paisa; quantity is the only decimal.
library;

/// Aggregate of a set of documents (sales) over a period.
class AmountSummaryEntity {
  final int count;
  final int subtotal;
  final int discount;
  final int tax;
  final int total;
  final int paid;
  final int due;

  const AmountSummaryEntity({
    this.count = 0,
    this.subtotal = 0,
    this.discount = 0,
    this.tax = 0,
    this.total = 0,
    this.paid = 0,
    this.due = 0,
  });
}

/// One bucket (day/week/month) of a trend series.
class TrendPointEntity {
  final DateTime date;
  final int sales;
  final int costOfGoods;
  final int grossProfit;
  final int purchases;
  final int expenses;
  final int income;
  final int netProfit;

  const TrendPointEntity({
    required this.date,
    this.sales = 0,
    this.costOfGoods = 0,
    this.grossProfit = 0,
    this.purchases = 0,
    this.expenses = 0,
    this.income = 0,
    this.netProfit = 0,
  });
}

/// A ranked item (top product / customer / supplier).
class TopItemEntity {
  final int id;
  final String name;
  final int amount;
  final double quantity;
  final int count;

  const TopItemEntity({
    required this.id,
    required this.name,
    this.amount = 0,
    this.quantity = 0,
    this.count = 0,
  });
}

/// Snapshot returned by GET /reports/dashboard.
class DashboardEntity {
  final DateTime asOf;
  final AmountSummaryEntity todaySales;
  final AmountSummaryEntity monthSales;
  final int todayPurchases;
  final int todayExpenses;
  final int todayIncome;
  final int todayGrossProfit;
  final int todayNetProfit;
  final int monthPurchases;
  final int monthExpenses;
  final int monthIncome;
  final int monthGrossProfit;
  final int monthNetProfit;
  final int totalReceivable;
  final int totalPayable;
  final int customerAdvances;
  final int supplierAdvances;
  final int stockCostValue;
  final int stockRetailValue;
  final int lowStockCount;
  final int productCount;
  final int customerCount;
  final List<TrendPointEntity> trend;
  final List<TopItemEntity> topProducts;
  final List<TopItemEntity> topCustomers;

  const DashboardEntity({
    required this.asOf,
    this.todaySales = const AmountSummaryEntity(),
    this.monthSales = const AmountSummaryEntity(),
    this.todayPurchases = 0,
    this.todayExpenses = 0,
    this.todayIncome = 0,
    this.todayGrossProfit = 0,
    this.todayNetProfit = 0,
    this.monthPurchases = 0,
    this.monthExpenses = 0,
    this.monthIncome = 0,
    this.monthGrossProfit = 0,
    this.monthNetProfit = 0,
    this.totalReceivable = 0,
    this.totalPayable = 0,
    this.customerAdvances = 0,
    this.supplierAdvances = 0,
    this.stockCostValue = 0,
    this.stockRetailValue = 0,
    this.lowStockCount = 0,
    this.productCount = 0,
    this.customerCount = 0,
    this.trend = const [],
    this.topProducts = const [],
    this.topCustomers = const [],
  });
}
