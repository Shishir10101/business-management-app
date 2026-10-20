import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khata/features/import/data/repositories/import_repository_impl.dart';
import 'package:khata/features/import/domain/entities/import_entities.dart';
import 'package:khata/features/import/domain/repositories/import_repository.dart';
import 'package:khata/features/import/presentation/pages/import_page.dart';
import 'package:khata/l10n/app_localizations.dart';

class FakeImportRepository implements ImportRepository {
  int previewCalls = 0;
  int importCalls = 0;
  int templateCalls = 0;

  ImportPreview previewResult = const ImportPreview(
    entity: 'products',
    totalRows: 3,
    validRows: 2,
    duplicateRows: 0,
    invalidRows: 1,
    columns: ['name', 'sellingPrice'],
    ignoredColumns: ['colour'],
    issues: [
      ImportIssue(row: 3, column: 'sellingPrice', message: 'not a number'),
    ],
  );

  ImportPreview cleanPreview = const ImportPreview(
    entity: 'products',
    totalRows: 2,
    validRows: 2,
    duplicateRows: 0,
    invalidRows: 0,
    columns: ['name', 'sellingPrice'],
  );

  ImportResult importResult = const ImportResult(
    entity: 'products',
    created: 5,
    skipped: 1,
  );

  @override
  Future<String> template(ImportTarget target) async {
    templateCalls++;
    return 'name,sku';
  }

  @override
  Future<ImportPreview> preview(ImportTarget target, String csv) async {
    previewCalls++;
    return previewResult;
  }

  @override
  Future<ImportOutcome> importCsv(ImportTarget target, String csv) async {
    importCalls++;
    return ImportOutcome(result: importResult);
  }
}

void main() {
  Future<FakeImportRepository> pump(WidgetTester tester) async {
    final repository = FakeImportRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [importRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ImportPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return repository;
  }

  testWidgets('offers both entities and explains the flow', (tester) async {
    await pump(tester);

    expect(find.text('Import from Excel'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Products'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Customers'), findsOneWidget);
    expect(find.text('Copy template'), findsOneWidget);
    expect(find.text('Paste from clipboard'), findsOneWidget);
  });

  testWidgets('check file asks the server and shows the counts',
      (tester) async {
    final repository = await pump(tester);

    await tester.enterText(
      find.byType(TextField),
      'name,sellingPrice\nRice,100\nOil,x\n',
    );
    await tester.tap(find.text('Check file'));
    await tester.pumpAndSettle();

    expect(repository.previewCalls, 1);
    expect(find.text('Check result'), findsOneWidget);
    expect(find.text('Rows: 3'), findsOneWidget);
    expect(find.text('Ready: 2'), findsOneWidget);
    expect(find.text('Need fixing: 1'), findsOneWidget);
  });

  testWidgets('lists the rows to fix and the ignored columns', (tester) async {
    await pump(tester);

    await tester.enterText(find.byType(TextField), 'name,sellingPrice\nOil,x\n');
    await tester.tap(find.text('Check file'));
    await tester.pumpAndSettle();

    expect(find.text('Row 3 · sellingPrice: not a number'), findsOneWidget);
    expect(find.text('Ignored columns: colour'), findsOneWidget);
    expect(
      find.text('Nothing will be imported until every row is fixed.'),
      findsOneWidget,
    );
  });

  testWidgets('import stays disabled while the file has invalid rows',
      (tester) async {
    await pump(tester);

    await tester.enterText(find.byType(TextField), 'name,sellingPrice\nOil,x\n');
    await tester.tap(find.text('Check file'));
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Import'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('a clean check enables import and reports the result',
      (tester) async {
    final repository = await pump(tester);
    repository.previewResult = repository.cleanPreview;

    await tester.enterText(
      find.byType(TextField),
      'name,sellingPrice\nRice,100\nOil,200\n',
    );
    await tester.tap(find.text('Check file'));
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Import'),
    );
    expect(button.onPressed, isNotNull);

    await tester.tap(find.widgetWithText(FilledButton, 'Import'));
    await tester.pumpAndSettle();

    // Confirmation first — an import must never be a single stray tap.
    expect(find.text('Import these rows?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Import'));
    await tester.pumpAndSettle();

    expect(repository.importCalls, 1);
    expect(find.text('Import complete'), findsOneWidget);
    expect(find.text('5 record(s) created'), findsOneWidget);
    expect(find.text('1 already existed and were skipped'), findsOneWidget);
  });
}
