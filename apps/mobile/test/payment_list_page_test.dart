import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khata/features/payments/data/repositories/payment_repository_impl.dart';
import 'package:khata/features/payments/domain/entities/payment_entity.dart';
import 'package:khata/features/payments/domain/repositories/payment_repository.dart';
import 'package:khata/features/payments/presentation/pages/payment_list_page.dart';
import 'package:khata/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// In-memory fake of PaymentRepository so the list and summary render without
/// a server. Search is applied locally, mirroring the server-side match.
class FakePaymentRepository implements PaymentRepository {
  final List<PaymentEntity> payments;
  final ReceivablePayableSummary summary;

  FakePaymentRepository({this.payments = const [], required this.summary});

  @override
  Future<PaymentPage> getPayments({
    String? partyType,
    int? partyId,
    String? direction,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? search,
    int page = 1,
    int pageSize = 100,
  }) async {
    final query = (search ?? '').toLowerCase();
    final filtered = query.isEmpty
        ? payments
        : payments
            .where((p) =>
                p.partyName.toLowerCase().contains(query) ||
                (p.reference?.toLowerCase().contains(query) ?? false))
            .toList();
    return PaymentPage(data: filtered, totalItems: filtered.length);
  }

  @override
  Future<ReceivablePayableSummary> getSummary() async => summary;

  @override
  Future<PaymentEntity> createPayment({
    required String partyType,
    required int partyId,
    required int amount,
    String? direction,
    DateTime? paymentDate,
    int? paymentMethodId,
    String? methodCode,
    String? reference,
    String? notes,
    int? saleId,
    int? purchaseId,
  }) async =>
      throw UnimplementedError();

  @override
  Future<List<PaymentMethodEntity>> getMethods() async => const [];

  @override
  Future<PaymentMethodEntity> createMethod({
    required String name,
    String? code,
    String? description,
    bool isDefault = false,
  }) async =>
      throw UnimplementedError();

  @override
  Future<PaymentMethodEntity> updateMethod(
    int id, {
    required String name,
    String? code,
    String? description,
    bool isActive = true,
    bool isDefault = false,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteMethod(int id) async => throw UnimplementedError();
}

void main() {
  final date = DateTime(2026, 10, 14);
  final fake = FakePaymentRepository(
    summary: const ReceivablePayableSummary(
      totalReceivable: 40000,
      totalPayable: 15000,
      customerAdvances: 0,
      supplierAdvances: 0,
      receivableParties: 1,
      payableParties: 1,
    ),
    payments: [
      PaymentEntity(
        id: 1,
        partyType: 'Customer',
        partyId: 1,
        partyName: 'Ram Shrestha',
        direction: 'In',
        amount: 6000,
        paymentDate: date,
        paymentMethodId: 1,
        methodName: 'Cash',
        reference: 'RCPT-1',
        saleId: 10,
        saleInvoiceNumber: 'INV-00001',
        appliedAmount: 6000,
        unappliedAmount: 0,
        createdAt: date,
      ),
      PaymentEntity(
        id: 2,
        partyType: 'Supplier',
        partyId: 2,
        partyName: 'Himal Traders',
        direction: 'Out',
        amount: 5000,
        paymentDate: date,
        paymentMethodId: 2,
        methodName: 'Bank Transfer',
        purchaseId: 20,
        purchaseBillNumber: 'BILL-00001',
        appliedAmount: 3000,
        unappliedAmount: 2000,
        createdAt: date,
      ),
    ],
  );

  Future<void> pumpList(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [paymentRepositoryProvider.overrideWithValue(fake)],
        child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const PaymentListPage(),
    ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the receivable/payable summary', (tester) async {
    await pumpList(tester);

    expect(find.text('To collect'), findsOneWidget);
    expect(find.text('To pay'), findsOneWidget);
    expect(find.text('Rs. 400.00'), findsOneWidget);
    expect(find.text('Rs. 150.00'), findsOneWidget);
  });

  testWidgets('renders payments with direction, document and advance',
      (tester) async {
    await pumpList(tester);

    expect(find.text('Ram Shrestha  •  Cash'), findsOneWidget);
    expect(find.text('Himal Traders  •  Bank Transfer'), findsOneWidget);
    expect(find.text('Rs. 60.00'), findsOneWidget);
    expect(find.text('Advance Rs. 20.00'), findsOneWidget);
    expect(find.textContaining('INV-00001'), findsOneWidget);
    expect(find.textContaining('BILL-00001'), findsOneWidget);
  });

  testWidgets('search filters by party name', (tester) async {
    await pumpList(tester);

    await tester.enterText(find.byType(TextField), 'himal');
    await tester.pumpAndSettle();

    expect(find.text('Himal Traders  •  Bank Transfer'), findsOneWidget);
    expect(find.text('Ram Shrestha  •  Cash'), findsNothing);
  });
}
