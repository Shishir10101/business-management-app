import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khata/features/invoices/data/repositories/invoice_repository_impl.dart';
import 'package:khata/features/invoices/domain/entities/invoice_entity.dart';
import 'package:khata/features/invoices/domain/repositories/invoice_repository.dart';
import 'package:khata/features/invoices/presentation/pages/invoice_list_page.dart';
import 'package:khata/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// In-memory fake of InvoiceRepository so the list can render without a server.
/// Search and status filters are applied locally, mirroring the server.
class FakeInvoiceRepository implements InvoiceRepository {
  final List<InvoiceEntity> invoices;

  FakeInvoiceRepository({this.invoices = const []});

  @override
  Future<InvoicePage> getInvoices({
    int? customerId,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? search,
    int page = 1,
    int pageSize = 100,
  }) async {
    var filtered = invoices;
    if (status != null) {
      filtered = filtered.where((i) => i.status == status).toList();
    }
    final query = (search ?? '').toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered
          .where((i) =>
              i.invoiceNumber.toLowerCase().contains(query) ||
              (i.customerName?.toLowerCase().contains(query) ?? false))
          .toList();
    }
    return InvoicePage(
        data: filtered, totalItems: filtered.length, totalPages: 1);
  }

  @override
  Future<InvoiceEntity> getInvoice(int id) async =>
      invoices.firstWhere((i) => i.id == id);

  @override
  Future<InvoiceEntity> createInvoice({
    int? customerId,
    int? saleId,
    DateTime? issueDate,
    DateTime? dueDate,
    required List<InvoiceLineDraft> items,
    int discountAmount = 0,
    String? notes,
    String? terms,
    String? status,
  }) async =>
      throw UnimplementedError();

  @override
  Future<InvoiceEntity> updateInvoice(
    int id, {
    int? customerId,
    DateTime? issueDate,
    DateTime? dueDate,
    required List<InvoiceLineDraft> items,
    int discountAmount = 0,
    String? notes,
    String? terms,
    String? status,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteInvoice(int id) async => throw UnimplementedError();

  @override
  Future<Uint8List> downloadPdf(int id) async => throw UnimplementedError();
}

void main() {
  final date = DateTime(2026, 10, 14);
  final fake = FakeInvoiceRepository(
    invoices: [
      InvoiceEntity(
        id: 1,
        invoiceNumber: 'INV-00001',
        customerId: 1,
        customerName: 'Hari Bahadur',
        status: 'Draft',
        issueDate: date,
        subtotal: 220000,
        taxAmount: 28600,
        totalAmount: 248600,
        createdAt: date,
        updatedAt: date,
      ),
      InvoiceEntity(
        id: 2,
        invoiceNumber: 'INV-00002',
        status: 'Sent',
        issueDate: date,
        subtotal: 50000,
        totalAmount: 50000,
        createdAt: date,
        updatedAt: date,
      ),
    ],
  );

  Future<void> pumpList(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [invoiceRepositoryProvider.overrideWithValue(fake)],
        child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const InvoiceListPage(),
    ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders invoice numbers, customers, totals and status',
      (tester) async {
    await pumpList(tester);

    expect(find.text('INV-00001  •  Hari Bahadur'), findsOneWidget);
    expect(find.text('INV-00002  •  Walk-in'), findsOneWidget);
    expect(find.text('Rs. 2,486.00'), findsOneWidget);
    expect(find.text('Rs. 500.00'), findsOneWidget);
    // One filter chip plus one tile chip for each status.
    expect(find.widgetWithText(ChoiceChip, 'Draft'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Sent'), findsOneWidget);
  });

  testWidgets('search filters by customer name and invoice number',
      (tester) async {
    await pumpList(tester);

    await tester.enterText(find.byType(TextField), 'hari');
    await tester.pumpAndSettle();

    expect(find.text('INV-00001  •  Hari Bahadur'), findsOneWidget);
    expect(find.text('INV-00002  •  Walk-in'), findsNothing);
  });

  testWidgets('status chip filters the list', (tester) async {
    await pumpList(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Sent'));
    await tester.pumpAndSettle();

    expect(find.text('INV-00002  •  Walk-in'), findsOneWidget);
    expect(find.text('INV-00001  •  Hari Bahadur'), findsNothing);
  });
}
