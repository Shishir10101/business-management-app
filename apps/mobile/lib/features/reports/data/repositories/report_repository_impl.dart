import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/report_entities.dart';
import '../../domain/repositories/report_repository.dart';
import '../datasources/report_remote_datasource.dart';

/// Implementation of ReportRepository against the Khata API.
class ReportRepositoryImpl implements ReportRepository {
  final ReportRemoteDatasource _remote;

  ReportRepositoryImpl(this._remote);

  @override
  Future<SalesReportEntity> getSalesReport({
    required DateTime from,
    required DateTime to,
    String groupBy = 'day',
    int top = 10,
  }) async {
    final json = await _remote.getSalesReport(
      from: from,
      to: to,
      groupBy: groupBy,
      top: top,
    );
    return SalesReportEntity(
      dateFrom: _dateFrom(json, from),
      dateTo: _dateTo(json, to),
      groupBy: json['groupBy'] as String? ?? groupBy,
      totals: _summaryFromJson(json['totals']),
      series: _seriesFromJson(json['series']),
      topProducts: _topItemsFromJson(json['topProducts']),
      topCustomers: _topItemsFromJson(json['topCustomers']),
    );
  }

  @override
  Future<PurchaseReportEntity> getPurchaseReport({
    required DateTime from,
    required DateTime to,
    String groupBy = 'day',
    int top = 10,
  }) async {
    final json = await _remote.getPurchaseReport(
      from: from,
      to: to,
      groupBy: groupBy,
      top: top,
    );
    return PurchaseReportEntity(
      dateFrom: _dateFrom(json, from),
      dateTo: _dateTo(json, to),
      groupBy: json['groupBy'] as String? ?? groupBy,
      totals: _summaryFromJson(json['totals']),
      series: _seriesFromJson(json['series']),
      topSuppliers: _topItemsFromJson(json['topSuppliers']),
    );
  }

  @override
  Future<ProfitLossEntity> getProfitLoss({
    required DateTime from,
    required DateTime to,
  }) async {
    final json = await _remote.getProfitLoss(from: from, to: to);
    return ProfitLossEntity(
      dateFrom: _dateFrom(json, from),
      dateTo: _dateTo(json, to),
      revenue: _int(json['revenue']),
      costOfGoods: _int(json['costOfGoods']),
      grossProfit: _int(json['grossProfit']),
      otherIncome: _int(json['otherIncome']),
      expenses: _int(json['expenses']),
      netProfit: _int(json['netProfit']),
      salesTaxCollected: _int(json['salesTaxCollected']),
      expensesByCategory: _categoriesFromJson(json['expensesByCategory']),
    );
  }

  @override
  Future<ExpenseReportEntity> getExpenseReport({
    required DateTime from,
    required DateTime to,
    String groupBy = 'day',
  }) async {
    final json = await _remote.getExpenseReport(
      from: from,
      to: to,
      groupBy: groupBy,
    );
    return ExpenseReportEntity(
      dateFrom: _dateFrom(json, from),
      dateTo: _dateTo(json, to),
      groupBy: json['groupBy'] as String? ?? groupBy,
      total: _int(json['total']),
      count: _int(json['count']),
      byCategory: _categoriesFromJson(json['byCategory']),
      series: _seriesFromJson(json['series']),
    );
  }

  @override
  Future<IncomeReportEntity> getIncomeReport({
    required DateTime from,
    required DateTime to,
    String groupBy = 'day',
  }) async {
    final json = await _remote.getIncomeReport(
      from: from,
      to: to,
      groupBy: groupBy,
    );
    return IncomeReportEntity(
      dateFrom: _dateFrom(json, from),
      dateTo: _dateTo(json, to),
      groupBy: json['groupBy'] as String? ?? groupBy,
      total: _int(json['total']),
      count: _int(json['count']),
      bySource: _categoriesFromJson(json['bySource']),
      series: _seriesFromJson(json['series']),
    );
  }

  @override
  Future<StockReportEntity> getStockReport({
    bool lowStockOnly = false,
    String? search,
  }) async {
    final json = await _remote.getStockReport(
      lowStockOnly: lowStockOnly,
      search: search,
    );
    return StockReportEntity(
      totalCostValue: _int(json['totalCostValue']),
      totalRetailValue: _int(json['totalRetailValue']),
      potentialMargin: _int(json['potentialMargin']),
      productCount: _int(json['productCount']),
      lowStockCount: _int(json['lowStockCount']),
      items: ((json['items'] as List<dynamic>?) ?? const [])
          .map((e) => _stockRowFromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Future<ReceivablePayableReportEntity> getReceivablePayable() async {
    final json = await _remote.getReceivablePayable();
    return ReceivablePayableReportEntity(
      totalReceivable: _int(json['totalReceivable']),
      totalPayable: _int(json['totalPayable']),
      customerAdvances: _int(json['customerAdvances']),
      supplierAdvances: _int(json['supplierAdvances']),
      receivables: _outstandingFromJson(json['receivables']),
      payables: _outstandingFromJson(json['payables']),
    );
  }

  @override
  Future<Uint8List> downloadCsv({
    required String type,
    required DateTime from,
    required DateTime to,
  }) =>
      _remote.downloadCsv(type: type, from: from, to: to);

  // --- mapping ---

  static DateTime _dateFrom(Map<String, dynamic> json, DateTime fallback) =>
      DateTime.tryParse(json['dateFrom'] as String? ?? '') ?? fallback;

  static DateTime _dateTo(Map<String, dynamic> json, DateTime fallback) =>
      DateTime.tryParse(json['dateTo'] as String? ?? '') ?? fallback;

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

  List<TrendPointEntity> _seriesFromJson(Object? value) {
    if (value is! List<dynamic>) return const [];
    return value.map((e) => _trendFromJson(e as Map<String, dynamic>)).toList();
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

  List<TopItemEntity> _topItemsFromJson(Object? value) {
    if (value is! List<dynamic>) return const [];
    return value
        .map((e) => _topItemFromJson(e as Map<String, dynamic>))
        .toList();
  }

  TopItemEntity _topItemFromJson(Map<String, dynamic> m) => TopItemEntity(
        id: _int(m['id']),
        name: m['name'] as String? ?? '',
        amount: _int(m['amount']),
        quantity: (m['quantity'] as num?)?.toDouble() ?? 0,
        count: _int(m['count']),
      );

  List<CategoryAmountEntity> _categoriesFromJson(Object? value) {
    if (value is! List<dynamic>) return const [];
    return value
        .map((e) => _categoryFromJson(e as Map<String, dynamic>))
        .toList();
  }

  CategoryAmountEntity _categoryFromJson(Map<String, dynamic> m) =>
      CategoryAmountEntity(
        category: m['category'] as String? ?? '',
        amount: _int(m['amount']),
        count: _int(m['count']),
      );

  StockRowEntity _stockRowFromJson(Map<String, dynamic> m) => StockRowEntity(
        productId: _int(m['productId']),
        name: m['name'] as String? ?? '',
        categoryName: m['categoryName'] as String?,
        unitShortName: m['unitShortName'] as String?,
        quantity: (m['quantity'] as num?)?.toDouble() ?? 0,
        costPrice: _int(m['costPrice']),
        sellingPrice: _int(m['sellingPrice']),
        costValue: _int(m['costValue']),
        retailValue: _int(m['retailValue']),
        isLowStock: m['isLowStock'] as bool? ?? false,
      );

  List<OutstandingPartyEntity> _outstandingFromJson(Object? value) {
    if (value is! List<dynamic>) return const [];
    return value
        .map((e) => _outstandingFromJsonItem(e as Map<String, dynamic>))
        .toList();
  }

  OutstandingPartyEntity _outstandingFromJsonItem(Map<String, dynamic> m) =>
      OutstandingPartyEntity(
        partyId: _int(m['partyId']),
        name: m['name'] as String? ?? '',
        phoneNumber: m['phoneNumber'] as String?,
        balance: _int(m['balance']),
        openDocuments: _int(m['openDocuments']),
      );

  static int _int(Object? value) => (value as num?)?.toInt() ?? 0;
}

/// Provider for the report repository implementation.
final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepositoryImpl(ref.read(reportRemoteDatasourceProvider));
});
