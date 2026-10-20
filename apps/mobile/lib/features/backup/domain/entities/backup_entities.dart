/// Backup domain entities. Pure Dart, no serialization.
library;

/// What a restore actually did, per table.
///
/// `skipped` is not a failure: restore is a merge, so rows the business
/// already has are deliberately left alone.
class BackupRestoreResult {
  final int businessId;
  final int productsInserted;
  final int productsSkipped;
  final int customersInserted;
  final int customersSkipped;
  final int suppliersInserted;
  final int suppliersSkipped;
  final int salesInserted;
  final int salesSkipped;
  final int purchasesInserted;
  final int purchasesSkipped;
  final int expensesInserted;
  final int expensesSkipped;
  final int incomesInserted;
  final int incomesSkipped;
  final int paymentsInserted;
  final int paymentsSkipped;
  final int invoicesInserted;
  final int invoicesSkipped;
  final int quotationsInserted;
  final int quotationsSkipped;
  final int paymentMethodsInserted;
  final int paymentMethodsMatched;
  final int unitsInserted;
  final int unitsMatched;

  const BackupRestoreResult({
    required this.businessId,
    required this.productsInserted,
    required this.productsSkipped,
    required this.customersInserted,
    required this.customersSkipped,
    required this.suppliersInserted,
    required this.suppliersSkipped,
    required this.salesInserted,
    required this.salesSkipped,
    required this.purchasesInserted,
    required this.purchasesSkipped,
    required this.expensesInserted,
    required this.expensesSkipped,
    required this.incomesInserted,
    required this.incomesSkipped,
    required this.paymentsInserted,
    required this.paymentsSkipped,
    required this.invoicesInserted,
    required this.invoicesSkipped,
    required this.quotationsInserted,
    required this.quotationsSkipped,
    required this.paymentMethodsInserted,
    required this.paymentMethodsMatched,
    required this.unitsInserted,
    required this.unitsMatched,
  });

  int get totalInserted =>
      productsInserted +
      customersInserted +
      suppliersInserted +
      salesInserted +
      purchasesInserted +
      expensesInserted +
      incomesInserted +
      paymentsInserted +
      invoicesInserted +
      quotationsInserted +
      paymentMethodsInserted +
      unitsInserted;

  int get totalSkipped =>
      productsSkipped +
      customersSkipped +
      suppliersSkipped +
      salesSkipped +
      purchasesSkipped +
      expensesSkipped +
      incomesSkipped +
      paymentsSkipped +
      invoicesSkipped +
      quotationsSkipped +
      paymentMethodsMatched +
      unitsMatched;

  /// Human-readable per-table breakdown, for the result dialog.
  List<(String, int, int)> get breakdown => [
        ('Products', productsInserted, productsSkipped),
        ('Customers', customersInserted, customersSkipped),
        ('Suppliers', suppliersInserted, suppliersSkipped),
        ('Sales', salesInserted, salesSkipped),
        ('Purchases', purchasesInserted, purchasesSkipped),
        ('Expenses', expensesInserted, expensesSkipped),
        ('Income', incomesInserted, incomesSkipped),
        ('Payments', paymentsInserted, paymentsSkipped),
        ('Invoices', invoicesInserted, invoicesSkipped),
        ('Quotations', quotationsInserted, quotationsSkipped),
      ].where((row) => row.$2 > 0 || row.$3 > 0).toList(growable: false);
}
