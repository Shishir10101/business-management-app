import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khata/features/parties/data/repositories/party_repository_impl.dart';
import 'package:khata/features/parties/domain/entities/party_entity.dart';
import 'package:khata/features/parties/domain/repositories/party_repository.dart';
import 'package:khata/features/parties/presentation/pages/party_list_page.dart';
import 'package:khata/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// In-memory fake of PartyRepository: returns a fixed set of parties so the
/// list can render without a server. Search is applied locally, mirroring the
/// server-side name/phone match.
class FakePartyRepository implements PartyRepository {
  final List<CustomerEntity> customers;
  final List<SupplierEntity> suppliers;

  FakePartyRepository({
    this.customers = const [],
    this.suppliers = const [],
  });

  @override
  Future<PartyPage<CustomerEntity>> getCustomers({
    String? search,
    int page = 1,
    int pageSize = 50,
  }) async {
    final q = (search ?? '').toLowerCase();
    final matches = q.isEmpty
        ? customers
        : customers
            .where((c) =>
                c.name.toLowerCase().contains(q) ||
                (c.phoneNumber?.contains(q) ?? false))
            .toList();
    return PartyPage<CustomerEntity>(
      items: matches,
      page: page,
      pageSize: pageSize,
      totalItems: matches.length,
      hasNext: false,
    );
  }

  @override
  Future<CustomerEntity> getCustomer(int id) async =>
      customers.firstWhere((c) => c.id == id);

  @override
  Future<PartyPage<SupplierEntity>> getSuppliers({
    String? search,
    int page = 1,
    int pageSize = 50,
  }) async {
    final q = (search ?? '').toLowerCase();
    final matches = q.isEmpty
        ? suppliers
        : suppliers
            .where((s) =>
                s.name.toLowerCase().contains(q) ||
                (s.phoneNumber?.contains(q) ?? false))
            .toList();
    return PartyPage<SupplierEntity>(
      items: matches,
      page: page,
      pageSize: pageSize,
      totalItems: matches.length,
      hasNext: false,
    );
  }

  @override
  Future<SupplierEntity> getSupplier(int id) async =>
      suppliers.firstWhere((s) => s.id == id);

  @override
  Future<CustomerEntity> createCustomer({
    required String name,
    String? phoneNumber,
    String? email,
    String? addressLine,
    String? city,
    String? district,
    int openingBalance = 0,
    String? panNumber,
    int? creditLimit,
    String? notes,
    bool isActive = true,
  }) async =>
      throw UnimplementedError();

  @override
  Future<CustomerEntity> updateCustomer(
    int id, {
    required String name,
    String? phoneNumber,
    String? email,
    String? addressLine,
    String? city,
    String? district,
    int openingBalance = 0,
    String? panNumber,
    int? creditLimit,
    String? notes,
    bool isActive = true,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteCustomer(int id) async => throw UnimplementedError();

  @override
  Future<PartyLedgerEntity> getCustomerLedger(int id) async =>
      throw UnimplementedError();

  @override
  Future<SupplierEntity> createSupplier({
    required String name,
    String? phoneNumber,
    String? email,
    String? addressLine,
    String? city,
    String? district,
    int openingBalance = 0,
    String? panNumber,
    String? notes,
    bool isActive = true,
  }) async =>
      throw UnimplementedError();

  @override
  Future<SupplierEntity> updateSupplier(
    int id, {
    required String name,
    String? phoneNumber,
    String? email,
    String? addressLine,
    String? city,
    String? district,
    int openingBalance = 0,
    String? panNumber,
    String? notes,
    bool isActive = true,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteSupplier(int id) async => throw UnimplementedError();

  @override
  Future<PartyLedgerEntity> getSupplierLedger(int id) async =>
      throw UnimplementedError();
}

void main() {
  final fake = FakePartyRepository(
    customers: const [
      // Balances are paisa. Positive = customer owes us; negative = advance.
      CustomerEntity(
          id: 1,
          name: 'Ram Shrestha',
          phoneNumber: '9800000001',
          currentBalance: 150000),
      CustomerEntity(
          id: 2,
          name: 'Sita Devi',
          phoneNumber: '9800000002',
          currentBalance: 50000),
      CustomerEntity(
          id: 3,
          name: 'Gita Gurung',
          phoneNumber: '9800000003',
          currentBalance: -5000),
    ],
    suppliers: const [
      SupplierEntity(
          id: 1,
          name: 'Himal Traders',
          phoneNumber: '9800000010',
          currentBalance: 250000),
      SupplierEntity(
          id: 2,
          name: 'Sagarmatha Supplies',
          phoneNumber: '9800000011',
          currentBalance: 100000),
    ],
  );

  Future<void> pumpList(WidgetTester tester, PartyKind kind) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          partyRepositoryProvider.overrideWithValue(fake),
        ],
        child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: PartyListPage(kind: kind),
    ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders customers with phone and khata balance labels',
      (tester) async {
    await pumpList(tester, PartyKind.customer);

    expect(find.text('Customers'), findsOneWidget);
    expect(find.text('Ram Shrestha'), findsOneWidget);
    expect(find.text('9800000001'), findsOneWidget);
    expect(find.text('Rs. 1,500.00'), findsOneWidget);
    // Two customers owe money; one has paid ahead.
    expect(find.text('To collect'), findsNWidgets(2));
    expect(find.text('Advance'), findsOneWidget);
  });

  testWidgets('search filters customers by name', (tester) async {
    await pumpList(tester, PartyKind.customer);

    await tester.enterText(find.byType(TextField), 'sita');
    await tester.pumpAndSettle();

    expect(find.text('Sita Devi'), findsOneWidget);
    expect(find.text('Ram Shrestha'), findsNothing);
  });

  testWidgets('renders suppliers with payable labels', (tester) async {
    await pumpList(tester, PartyKind.supplier);

    expect(find.text('Suppliers'), findsOneWidget);
    expect(find.text('Himal Traders'), findsOneWidget);
    expect(find.text('Rs. 2,500.00'), findsOneWidget);
    expect(find.text('To pay'), findsNWidgets(2));
  });
}
