import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khata/features/sales/data/repositories/sale_repository_impl.dart';
import 'package:khata/features/sales/domain/entities/sale_entity.dart';
import 'package:khata/features/sales/domain/repositories/sale_repository.dart';
import 'package:khata/features/sales/presentation/pages/sale_list_page.dart';
import 'package:khata/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// In-memory fake of SaleRepository: applies the payment-status and search
/// filters locally so the list can render without a server.
class FakeSaleRepository implements SaleRepository {
  final List<SaleEntity> sales;

  FakeSaleRepository({this.sales = const []});

  @override
  Future<SalePage> getSales({
    int? customerId,
    String? saleType,
    String? paymentStatus,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    var filtered = sales;
    if (paymentStatus != null) {
      filtered =
          filtered.where((s) => s.paymentStatus == paymentStatus).toList();
    }
    final query = (search ?? '').toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered
          .where((s) =>
              s.invoiceNumber.toLowerCase().contains(query) ||
              (s.customerName?.toLowerCase().contains(query) ?? false))
          .toList();
    }
    return SalePage(data: filtered, totalItems: filtered.length, totalPages: 1);
  }

  @override
  Future<SaleEntity> getSale(int id) async =>
      sales.firstWhere((s) => s.id == id);

  @override
  Future<SaleEntity> createSale({
    int? customerId,
    required String saleType,
    DateTime? saleDate,
    required List<SaleLineDraft> items,
    int discountAmount = 0,
    int paidAmount = 0,
    String? notes,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteSale(int id) async => throw UnimplementedError();
}

void main() {
  final now = DateTime(2026, 10, 5);
  final fake = FakeSaleRepository(
    sales: [
      SaleEntity(
        id: 1,
        invoiceNumber: 'INV-00001',
        customerId: 1,
        customerName: 'Ram Shrestha',
        saleType: 'Credit',
        paymentStatus: 'Unpaid',
        saleDate: now,
        subtotal: 50000,
        totalAmount: 50000,
        dueAmount: 50000,
        createdAt: now,
        updatedAt: now,
      ),
      SaleEntity(
        id: 2,
        invoiceNumber: 'INV-00002',
        customerName: 'Sita Devi',
        saleType: 'Cash',
        paymentStatus: 'Paid',
        saleDate: now,
        subtotal: 20000,
        totalAmount: 20000,
        paidAmount: 20000,
        dueAmount: 0,
        createdAt: now,
        updatedAt: now,
      ),
    ],
  );

  Future<void> pumpList(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [saleRepositoryProvider.overrideWithValue(fake)],
        child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SaleListPage(),
    ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders invoices, customers, totals and due labels',
      (tester) async {
    await pumpList(tester);

    expect(find.text('INV-00001  •  Ram Shrestha'), findsOneWidget);
    expect(find.text('INV-00002  •  Sita Devi'), findsOneWidget);
    expect(find.text('Rs. 500.00'), findsOneWidget);
    expect(find.text('Due Rs. 500.00'), findsOneWidget);
    expect(find.text('Rs. 200.00'), findsOneWidget);
  });

  testWidgets('search filters by customer name', (tester) async {
    await pumpList(tester);

    await tester.enterText(find.byType(TextField), 'sita');
    await tester.pumpAndSettle();

    expect(find.text('INV-00002  •  Sita Devi'), findsOneWidget);
    expect(find.text('INV-00001  •  Ram Shrestha'), findsNothing);
  });

  testWidgets('payment-status chip filters the list', (tester) async {
    await pumpList(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Paid'));
    await tester.pumpAndSettle();

    expect(find.text('INV-00002  •  Sita Devi'), findsOneWidget);
    expect(find.text('INV-00001  •  Ram Shrestha'), findsNothing);
  });
}
