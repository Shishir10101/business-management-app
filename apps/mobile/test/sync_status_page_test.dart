import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khata/features/sync/data/repositories/sync_repository_impl.dart';
import 'package:khata/features/sync/domain/repositories/sync_repository.dart';
import 'package:khata/features/sync/domain/entities/sync_entities.dart';
import 'package:khata/features/sync/presentation/pages/sync_status_page.dart';
import 'package:khata/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Fake SyncRepository that counts sync attempts and returns a fixed outcome.
class FakeSyncRepository implements SyncRepository {
  int syncNowCalls = 0;
  final SyncOutcome outcome;

  FakeSyncRepository()
      : outcome = SyncOutcome(serverTime: DateTime.utc(2026, 10, 14, 11, 0));

  @override
  Future<SyncOutcome> syncNow() async {
    syncNowCalls++;
    return outcome;
  }

  @override
  Future<SyncOperationHandle> enqueue({
    required String entityType,
    required String operation,
    required String entityId,
    Map<String, dynamic>? payload,
    DateTime? baseUpdatedAt,
  }) async =>
      throw UnimplementedError();

  @override
  Future<List<QueuedOperation>> queuedOperations() async => const [];

  @override
  Future<List<SyncConflict>> persistedConflicts() async => const [];

  @override
  Future<DateTime?> lastSyncAt() async => null;
}

void main() {
  Future<FakeSyncRepository> pumpPage(WidgetTester tester) async {
    final repository = FakeSyncRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [syncRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SyncStatusPage(),
    ),
      ),
    );
    await tester.pumpAndSettle();
    return repository;
  }

  testWidgets('renders the sync status page', (tester) async {
    await pumpPage(tester);

    expect(find.text('Sync status'), findsWidgets);
    expect(find.text('Sync now'), findsOneWidget);
  });

  testWidgets('Sync now delegates to the repository', (tester) async {
    final repository = await pumpPage(tester);

    await tester.tap(find.text('Sync now'));
    await tester.pumpAndSettle();

    expect(repository.syncNowCalls, greaterThan(0));
  });
}
