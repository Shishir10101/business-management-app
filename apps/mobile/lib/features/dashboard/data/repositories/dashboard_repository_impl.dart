import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/dashboard_entity.dart';
import '../datasources/dashboard_remote_datasource.dart';

/// Reads the dashboard snapshot from the reports API.
class DashboardRepositoryImpl {
  final DashboardRemoteDatasource _remote;

  DashboardRepositoryImpl(this._remote);

  Future<DashboardEntity> getDashboard() async {
    final json = await _remote.getDashboard();
    return _dashboardFromJson(json);
  }

  // --- mapping ---

  DashboardEntity _dashboardFromJson(Map<String, dynamic> m) {
    return DashboardEntity(
      asOf: DateTime.tryParse(m['asOf'] as String? ?? '') ?? DateTime.now(),
      todaySales: _summaryFromJson(m['todaySales']),
      monthSales: _summaryFromJson(m['monthSales']),
      todayPurchases: _int(m['todayPurchases']),
      todayExpenses: _int(m['todayExpenses']),
      todayIncome: _int(m['todayIncome']),
      todayGrossProfit: _int(m['todayGrossProfit']),
      todayNetProfit: _int(m['todayNetProfit']),
      monthPurchases: _int(m['monthPurchases']),
      monthExpenses: _int(m['monthExpenses']),
      monthIncome: _int(m['monthIncome']),
      monthGrossProfit: _int(m['monthGrossProfit']),
      monthNetProfit: _int(m['monthNetProfit']),
      totalReceivable: _int(m['totalReceivable']),
      totalPayable: _int(m['totalPayable']),
      customerAdvances: _int(m['customerAdvances']),
      supplierAdvances: _int(m['supplierAdvances']),
      stockCostValue: _int(m['stockCostValue']),
      stockRetailValue: _int(m['stockRetailValue']),
      lowStockCount: _int(m['lowStockCount']),
      productCount: _int(m['productCount']),
      customerCount: _int(m['customerCount']),
      trend: ((m['trend'] as List<dynamic>?) ?? const [])
          .map((e) => _trendFromJson(e as Map<String, dynamic>))
          .toList(),
      topProducts: ((m['topProducts'] as List<dynamic>?) ?? const [])
          .map((e) => _topItemFromJson(e as Map<String, dynamic>))
          .toList(),
      topCustomers: ((m['topCustomers'] as List<dynamic>?) ?? const [])
          .map((e) => _topItemFromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  AmountSummaryEntity _summaryFromJson(Object? value) {
    if (value is! Map<String, dynamic>) return const AmountSummaryEntity();
    return AmountSummaryEntity(
      count: _int(value['count']),
      subtotal: _int(value['subtotal']),
      discount: _int(value['discount']),
      tax: _int(value['tax']),
      total: _int(value['total']),
      paid: _int(value['paid']),
      due: _int(value['due']),
    );
  }

  TrendPointEntity _trendFromJson(Map<String, dynamic> m) => TrendPointEntity(
        date: DateTime.tryParse(m['date'] as String? ?? '') ?? DateTime.now(),
        sales: _int(m['sales']),
        costOfGoods: _int(m['costOfGoods']),
        grossProfit: _int(m['grossProfit']),
        purchases: _int(m['purchases']),
        expenses: _int(m['expenses']),
        income: _int(m['income']),
        netProfit: _int(m['netProfit']),
      );

  TopItemEntity _topItemFromJson(Map<String, dynamic> m) => TopItemEntity(
        id: _int(m['id']),
        name: m['name'] as String? ?? '',
        amount: _int(m['amount']),
        quantity: (m['quantity'] as num?)?.toDouble() ?? 0,
        count: _int(m['count']),
      );

  static int _int(Object? value) => (value as num?)?.toInt() ?? 0;
}

/// Provider for the dashboard repository implementation.
final dashboardRepositoryProvider = Provider<DashboardRepositoryImpl>((ref) {
  return DashboardRepositoryImpl(ref.read(dashboardRemoteDatasourceProvider));
});
