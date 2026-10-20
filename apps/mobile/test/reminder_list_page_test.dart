import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khata/features/reminders/data/repositories/reminder_repository_impl.dart';
import 'package:khata/features/reminders/domain/entities/reminder_entity.dart';
import 'package:khata/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:khata/features/reminders/presentation/pages/reminder_list_page.dart';
import 'package:khata/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Fake ReminderRepository backed by an in-memory list.
class FakeReminderRepository implements ReminderRepository {
  FakeReminderRepository(this._reminders);

  final List<ReminderEntity> _reminders;
  int processDueCalls = 0;
  final List<int> completed = [];
  final List<int> dismissed = [];
  final List<int> deleted = [];

  @override
  Future<List<ReminderEntity>> getReminders({ReminderStatus? status}) async {
    if (status == null) return List.of(_reminders);
    return _reminders.where((r) => r.status == status).toList();
  }

  @override
  Future<ReminderEntity> getReminder(int id) async =>
      _reminders.firstWhere((r) => r.id == id);

  @override
  Future<ReminderEntity> createReminder({
    required String title,
    required DateTime dueAt,
    String? notes,
    ReminderRepeat repeat = ReminderRepeat.none,
    String? relatedEntityType,
    int? relatedEntityId,
  }) async =>
      throw UnimplementedError();

  @override
  Future<ReminderEntity> updateReminder(
    int id, {
    required String title,
    required DateTime dueAt,
    String? notes,
    ReminderRepeat repeat = ReminderRepeat.none,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> completeReminder(int id) async => completed.add(id);

  @override
  Future<void> dismissReminder(int id) async => dismissed.add(id);

  @override
  Future<void> deleteReminder(int id) async => deleted.add(id);

  @override
  Future<int> processDue() async {
    processDueCalls++;
    return 0;
  }
}

ReminderEntity _reminder({
  required int id,
  required String title,
  required DateTime dueAt,
  ReminderStatus status = ReminderStatus.pending,
  ReminderRepeat repeat = ReminderRepeat.none,
  String? notes,
}) =>
    ReminderEntity(
      id: id,
      title: title,
      dueAt: dueAt,
      status: status,
      repeat: repeat,
      notes: notes,
    );

void main() {
  Future<FakeReminderRepository> pump(
    WidgetTester tester,
    List<ReminderEntity> reminders,
  ) async {
    final repository = FakeReminderRepository(reminders);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [reminderRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const ReminderListPage(),
    ),
      ),
    );
    await tester.pumpAndSettle();
    return repository;
  }

  testWidgets('shows an empty state with no reminders', (tester) async {
    await pump(tester, const []);

    expect(find.text('Nothing here'), findsOneWidget);
  });

  testWidgets('separates overdue reminders from scheduled ones',
      (tester) async {
    final now = DateTime.now();
    await pump(tester, [
      _reminder(
        id: 1,
        title: 'Overdue bill',
        dueAt: now.subtract(const Duration(days: 2)),
      ),
      _reminder(
        id: 2,
        title: 'Future task',
        dueAt: now.add(const Duration(days: 3)),
      ),
    ]);

    expect(find.text('Needs attention'), findsOneWidget);
    expect(find.text('Scheduled'), findsOneWidget);
    expect(find.text('Overdue bill'), findsOneWidget);
    expect(find.text('Future task'), findsOneWidget);
  });

  testWidgets('flags an overdue reminder in its subtitle', (tester) async {
    final now = DateTime.now();
    await pump(tester, [
      _reminder(
        id: 1,
        title: 'Overdue bill',
        dueAt: now.subtract(const Duration(hours: 5)),
      ),
    ]);

    expect(find.textContaining('Overdue'), findsWidgets);
  });

  testWidgets('does not flag a future reminder as overdue', (tester) async {
    await pump(tester, [
      _reminder(
        id: 2,
        title: 'Future task',
        dueAt: DateTime.now().add(const Duration(days: 5)),
      ),
    ]);

    expect(find.textContaining('· Overdue'), findsNothing);
  });

  testWidgets('shows the repeat cadence for a recurring reminder',
      (tester) async {
    await pump(tester, [
      _reminder(
        id: 3,
        title: 'Weekly report',
        dueAt: DateTime.now().add(const Duration(days: 1)),
        repeat: ReminderRepeat.weekly,
      ),
    ]);

    expect(find.textContaining('Every week'), findsOneWidget);
  });

  testWidgets('completing a reminder delegates to the repository',
      (tester) async {
    final repository = await pump(tester, [
      _reminder(
        id: 7,
        title: 'Call Ram',
        dueAt: DateTime.now().add(const Duration(hours: 1)),
      ),
    ]);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark done'));
    await tester.pumpAndSettle();

    expect(repository.completed, contains(7));
  });

  testWidgets('the due check delegates to the repository', (tester) async {
    final repository = await pump(tester, [
      _reminder(
        id: 1,
        title: 'Call Ram',
        dueAt: DateTime.now().add(const Duration(hours: 1)),
      ),
    ]);

    await tester.tap(find.byIcon(Icons.play_circle_outline));
    await tester.pumpAndSettle();

    expect(repository.processDueCalls, 1);
    expect(find.text('Nothing is due right now'), findsOneWidget);
  });

  testWidgets('hides the action menu for a completed reminder', (tester) async {
    await pump(tester, [
      _reminder(
        id: 9,
        title: 'Already done',
        dueAt: DateTime.now().subtract(const Duration(days: 1)),
        status: ReminderStatus.done,
      ),
    ]);

    // The default filter is "pending", so switch to "All" to see it.
    await tester.tap(find.byType(PopupMenuButton<ReminderStatus?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    expect(find.text('Already done'), findsOneWidget);
    expect(find.byType(PopupMenuButton<String>), findsNothing);
    expect(find.textContaining('Done'), findsWidgets);
  });

  testWidgets('the add button is present', (tester) async {
    await pump(tester, const []);

    expect(find.text('Add reminder'), findsOneWidget);
  });
}
