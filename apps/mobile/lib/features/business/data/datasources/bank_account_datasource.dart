import '../../../../core/network/dio_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

/// A bank account of the active business, mirroring the API's BankAccountDto.
class BankAccount {
  const BankAccount({
    required this.id,
    required this.bankName,
    required this.accountName,
    required this.accountNumber,
    this.branch,
    this.isDefault = false,
    this.isActive = true,
    this.paymentCount = 0,
    this.totalPaisa = 0,
  });

  final int id;
  final String bankName;
  final String accountName;
  final String accountNumber;
  final String? branch;
  final bool isDefault;
  final bool isActive;

  /// Payments recorded through this account, and their total in paisa.
  final int paymentCount;
  final int totalPaisa;

  /// Last four digits, for display where the full number is too long.
  String get masked =>
      accountNumber.length <= 4
          ? accountNumber
          : '•••• ${accountNumber.substring(accountNumber.length - 4)}';

  factory BankAccount.fromJson(Map<String, dynamic> json) => BankAccount(
        id: (json['id'] as num).toInt(),
        bankName: json['bankName'] as String? ?? '',
        accountName: json['accountName'] as String? ?? '',
        accountNumber: json['accountNumber'] as String? ?? '',
        branch: json['branch'] as String?,
        isDefault: json['isDefault'] as bool? ?? false,
        isActive: json['isActive'] as bool? ?? true,
        paymentCount: (json['paymentCount'] as num?)?.toInt() ?? 0,
        totalPaisa: (json['totalPaisa'] as num?)?.toInt() ?? 0,
      );
}

/// Bank account CRUD against `/api/businesses/{id}/bank-accounts`.
class BankAccountRemoteDatasource {
  BankAccountRemoteDatasource(this._dio);

  final Dio _dio;

  Future<List<BankAccount>> list(int businessId) async {
    final response = await _dio.get('/businesses/$businessId/bank-accounts');
    return (response.data as List<dynamic>)
        .map((e) => BankAccount.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BankAccount> create({
    required int businessId,
    required String bankName,
    required String accountName,
    required String accountNumber,
    String? branch,
    bool isDefault = false,
  }) async {
    final response = await _dio.post(
      '/businesses/$businessId/bank-accounts',
      data: {
        'bankName': bankName,
        'accountName': accountName,
        'accountNumber': accountNumber,
        'branch': branch,
        'isDefault': isDefault,
      },
    );
    return BankAccount.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(int businessId, int accountId) async {
    await _dio.delete('/businesses/$businessId/bank-accounts/$accountId');
  }
}

final bankAccountDatasourceProvider = Provider<BankAccountRemoteDatasource>(
  (ref) => BankAccountRemoteDatasource(ref.read(dioProvider)),
);
