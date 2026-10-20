import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/backup_entities.dart';
import '../../domain/repositories/backup_repository.dart';
import '../datasources/backup_remote_datasource.dart';

/// BackupRepository backed by the Khata API.
class BackupRepositoryImpl implements BackupRepository {
  BackupRepositoryImpl(this._remote);

  final BackupRemoteDatasource _remote;

  @override
  Future<List<int>> export() => _remote.export();

  @override
  Future<BackupRestoreResult> restore(Map<String, dynamic> payload) async =>
      _parse(await _remote.restore(payload));

  /// Decodes a snapshot from bytes read off the device. Throws
  /// [FormatException] with a readable message rather than letting a raw
  /// cast blow up, because the file is user-supplied.
  static Map<String, dynamic> decode(List<int> bytes) {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('This file is not a Khata backup.');
    }
    if (decoded['version'] is! num) {
      throw const FormatException('This file is not a Khata backup.');
    }
    return decoded;
  }

  static BackupRestoreResult _parse(Map<String, dynamic> json) {
    int at(String key) => (json[key] as num?)?.toInt() ?? 0;
    return BackupRestoreResult(
      businessId: at('businessId'),
      productsInserted: at('productsInserted'),
      productsSkipped: at('productsSkipped'),
      customersInserted: at('customersInserted'),
      customersSkipped: at('customersSkipped'),
      suppliersInserted: at('suppliersInserted'),
      suppliersSkipped: at('suppliersSkipped'),
      salesInserted: at('salesInserted'),
      salesSkipped: at('salesSkipped'),
      purchasesInserted: at('purchasesInserted'),
      purchasesSkipped: at('purchasesSkipped'),
      expensesInserted: at('expensesInserted'),
      expensesSkipped: at('expensesSkipped'),
      incomesInserted: at('incomesInserted'),
      incomesSkipped: at('incomesSkipped'),
      paymentsInserted: at('paymentsInserted'),
      paymentsSkipped: at('paymentsSkipped'),
      invoicesInserted: at('invoicesInserted'),
      invoicesSkipped: at('invoicesSkipped'),
      quotationsInserted: at('quotationsInserted'),
      quotationsSkipped: at('quotationsSkipped'),
      paymentMethodsInserted: at('paymentMethodsInserted'),
      paymentMethodsMatched: at('paymentMethodsMatched'),
      unitsInserted: at('unitsInserted'),
      unitsMatched: at('unitsMatched'),
    );
  }
}

/// Provider for the backup repository.
final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  return BackupRepositoryImpl(ref.read(backupRemoteDatasourceProvider));
});
