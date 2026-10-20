import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khata/features/products/data/repositories/product_repository_impl.dart';
import 'package:khata/features/products/domain/entities/product_entity.dart';
import 'package:khata/features/products/domain/repositories/product_repository.dart';
import 'package:khata/features/products/presentation/pages/product_list_page.dart';
import 'package:khata/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// In-memory fake of ProductRepository: returns a fixed catalog so the
/// product list can render without a server.
class FakeProductRepository implements ProductRepository {
  final List<CategoryEntity> categories = const [
    CategoryEntity(id: 1, name: 'General'),
  ];
  final List<UnitEntity> units = const [
    UnitEntity(id: 1, name: 'Piece', shortName: 'pc'),
  ];
  final List<ProductEntity> products;

  /// Rows the server returns for page 2+. Empty = a single-page catalog.
  final List<ProductEntity> nextPage;

  FakeProductRepository({required this.products, this.nextPage = const []});

  @override
  Future<List<CategoryEntity>> getCategories() async => categories;

  @override
  Future<List<UnitEntity>> getUnits() async => units;

  @override
  Future<ProductPage> getProducts({
    String? search,
    int? categoryId,
    bool? isActive,
    int page = 1,
    int pageSize = 20,
  }) async {
    final filtered = products.where((p) {
      if (search == null || search.isEmpty) return true;
      final q = search.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          (p.sku?.toLowerCase().contains(q) ?? false);
    }).toList();
    final total = filtered.length + nextPage.length;
    if (page > 1) {
      return ProductPage(
        data: nextPage,
        page: page,
        pageSize: pageSize,
        totalItems: total,
        totalPages: 2,
        hasNext: false,
        hasPrev: true,
      );
    }
    return ProductPage(
      data: filtered,
      page: 1,
      pageSize: pageSize,
      totalItems: total,
      totalPages: nextPage.isEmpty ? 1 : 2,
      hasNext: nextPage.isNotEmpty,
      hasPrev: false,
    );
  }

  @override
  Future<CategoryEntity> createCategory({
    required String name,
    String? description,
    int? parentId,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> updateCategory(
    int id, {
    required String name,
    String? description,
    int? parentId,
    bool isActive = true,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteCategory(int id) async => throw UnimplementedError();

  @override
  Future<UnitEntity> createUnit({
    required String name,
    required String shortName,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> updateUnit(
    int id, {
    required String name,
    required String shortName,
    bool isActive = true,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteUnit(int id) async => throw UnimplementedError();

  @override
  Future<ProductEntity> getProduct(int id) async =>
      products.firstWhere((p) => p.id == id);

  @override
  Future<ProductEntity> createProduct({
    required String name,
    int? categoryId,
    int? unitId,
    String? sku,
    String? barcode,
    String? description,
    int costPrice = 0,
    int sellingPrice = 0,
    int? wholesalePrice,
    int taxRateBps = 0,
    String? imageUrl,
    bool isActive = true,
    double openingQuantity = 0,
    double minQuantity = 0,
  }) async =>
      throw UnimplementedError();

  @override
  Future<ProductEntity> updateProduct(
    int id, {
    required String name,
    int? categoryId,
    int? unitId,
    String? sku,
    String? barcode,
    String? description,
    int costPrice = 0,
    int sellingPrice = 0,
    int? wholesalePrice,
    int taxRateBps = 0,
    String? imageUrl,
    bool isActive = true,
    double minQuantity = 0,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteProduct(int id) async => throw UnimplementedError();
}

void main() {
  final fake = FakeProductRepository(
    products: const [
      ProductEntity(
        id: 1,
        name: 'Wai Wai Noodles',
        sku: 'WW-001',
        sellingPrice: 2000,
        stockQuantity: 25,
        minQuantity: 10,
        categoryName: 'General',
        unitShortName: 'pc',
      ),
      ProductEntity(
        id: 2,
        name: 'Sugar',
        sku: 'SG-002',
        sellingPrice: 6000,
        stockQuantity: 3,
        minQuantity: 10,
        isLowStock: true,
        unitShortName: 'kg',
      ),
    ],
  );

  Future<void> pumpProductList(
    WidgetTester tester, {
    FakeProductRepository? repository,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productRepositoryProvider.overrideWithValue(repository ?? fake),
        ],
        child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const ProductListPage(),
    ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders product names, prices and stock quantities',
      (tester) async {
    await pumpProductList(tester);

    expect(find.text('Wai Wai Noodles'), findsOneWidget);
    expect(find.text('Sugar'), findsOneWidget);
    expect(find.textContaining('Rs. 20.00'), findsOneWidget);
    expect(find.text('25 pc'), findsOneWidget);
    expect(find.text('3 kg'), findsOneWidget);
    expect(find.text('Low stock'), findsOneWidget);
  });

  testWidgets('a paged catalog offers the rest and appends it', (tester) async {
    // The defect this covers: the list used to stop at the first page with no
    // hint that more products existed.
    final paged = FakeProductRepository(
      products: const [ProductEntity(id: 1, name: 'Rice')],
      nextPage: const [ProductEntity(id: 2, name: 'Lentils')],
    );
    await pumpProductList(tester, repository: paged);

    expect(find.text('Rice'), findsOneWidget);
    expect(find.text('Lentils'), findsNothing);
    expect(find.text('Load more (1 remaining)'), findsOneWidget);

    await tester.tap(find.text('Load more (1 remaining)'));
    await tester.pumpAndSettle();

    expect(find.text('Rice'), findsOneWidget);
    expect(find.text('Lentils'), findsOneWidget);
    expect(find.textContaining('Load more'), findsNothing);
  });

  testWidgets('search filters the list', (tester) async {
    await pumpProductList(tester);

    await tester.enterText(find.byType(TextField), 'sugar');
    await tester.pumpAndSettle();

    expect(find.text('Sugar'), findsOneWidget);
    expect(find.text('Wai Wai Noodles'), findsNothing);
  });
}
