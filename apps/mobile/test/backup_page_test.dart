import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khata/features/backup/data/repositories/backup_repository_impl.dart';
import 'package:khata/features/backup/domain/entities/backup_entities.dart';
import 'package:khata/features/backup/domain/repositories/backup_repository.dart';
import 'package:khata/features/backup/presentation/pages/backup_page.dart';
import 'package:khata/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class FakeBackupRepository implements BackupRepository {
  int exportCalls = 0;
  int restoreCalls = 0;
  BackupRestoreResult result = const BackupRestoreResult(
    businessId: 3,
    productsInserted: 5,
    productsSkipped: 0,
    customersInserted: 2,
    customersSkipped: 0,
    suppliersInserted: 1,
    suppliersSkipped: 0,
    salesInserted: 4,
    salesSkipped: 0,
    purchasesInserted: 3,
    purchasesSkipped: 0,
    expensesInserted: 1,
    expensesSkipped: 0,
    incomesInserted: 1,
    incomesSkipped: 0,
    paymentsInserted: 2,
    paymentsSkipped: 0,
    invoicesInserted: 1,
    invoicesSkipped: 0,
    quotationsInserted: 0,
    quotationsSkipped: 0,
    paymentMethodsInserted: 0,
    paymentMethodsMatched: 5,
    unitsInserted: 0,
    unitsMatched: 4,
  );

  @override
  Future<List<int>> export() async {
    exportCalls++;
    return const [123, 34, 118, 101, 114];
  }

  @override
  Future<BackupRestoreResult> restore(Map<String, dynamic> payload) async {
    restoreCalls++;
    return result;
  }
}

void main() {
  Future<FakeBackupRepository> pump(WidgetTester tester) async {
    final repository = FakeBackupRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [backupRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const BackupPage(),
    ),
      ),
    );
    await tester.pumpAndSettle();
    return repository;
  }

  testWidgets('renders both export and restore affordances', (tester) async {
    await pump(tester);

    expect(find.text('Backup & restore'), findsOneWidget);
    expect(find.text('Export backup'), findsOneWidget);
    expect(find.text('Restore from pasted JSON'), findsOneWidget);
  });

  testWidgets('explains that derived ledgers are not in the snapshot',
      (tester) async {
    await pump(tester);

    expect(find.text('What is not included'), findsOneWidget);
  });

  testWidgets('export delegates to the repository', (tester) async {
    final repository = await pump(tester);

    await tester.tap(find.text('Export backup'));
    await tester.pumpAndSettle();

    // The file write needs a real documents directory, which the test
    // environment does not provide; the repository call is what matters here.
    expect(repository.exportCalls, 1);
  });

  testWidgets('restore asks for confirmation before doing anything',
      (tester) async {
    final repository = await pump(tester);

    await tester.tap(find.text('Restore from pasted JSON'));
    await tester.pumpAndSettle();

    // Clipboard is empty in a test, so nothing is restored.
    expect(repository.restoreCalls, 0);
    expect(find.text('Clipboard is empty'), findsOneWidget);
  });
}
