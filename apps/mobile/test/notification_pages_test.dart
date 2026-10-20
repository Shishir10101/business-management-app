import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khata/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:khata/features/notifications/domain/entities/notification_entity.dart';
import 'package:khata/features/notifications/domain/repositories/notification_repository.dart';
import 'package:khata/features/notifications/presentation/pages/notification_list_page.dart';
import 'package:khata/features/notifications/presentation/pages/notification_settings_page.dart';
import 'package:khata/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class FakeNotificationRepository implements NotificationRepository {
  FakeNotificationRepository(this._feed, {this.unread = 0});

  final List<NotificationEntity> _feed;
  int unread;
  final List<int> markedRead = [];
  int markAllReadCalls = 0;
  final List<int> deleted = [];
  NotificationSettingsEntity settings = NotificationSettingsEntity.allOn;

  @override
  Future<List<NotificationEntity>> getNotifications({
    bool unreadOnly = false,
    NotificationCategory? category,
  }) async {
    var rows = List.of(_feed);
    if (unreadOnly) rows = rows.where((n) => !n.isRead).toList();
    if (category != null)
      rows = rows.where((n) => n.category == category).toList();
    return rows;
  }

  @override
  Future<int> getUnreadCount() async => unread;

  @override
  Future<void> markRead(int id) async {
    markedRead.add(id);
    unread = unread > 0 ? unread - 1 : 0;
    final index = _feed.indexWhere((n) => n.id == id);
    if (index != -1) _feed[index] = _feed[index].copyWith(isRead: true);
  }

  @override
  Future<int> markAllRead() async {
    markAllReadCalls++;
    final was = unread;
    unread = 0;
    for (var i = 0; i < _feed.length; i++) {
      _feed[i] = _feed[i].copyWith(isRead: true);
    }
    return was;
  }

  @override
  Future<void> delete(int id) async => deleted.add(id);

  @override
  Future<void> registerDevice({
    required String token,
    required String platform,
  }) async {}

  @override
  Future<List<DeviceEntity>> getDevices() async => const [];

  @override
  Future<NotificationSettingsEntity> getSettings() async => settings;

  @override
  Future<NotificationSettingsEntity> updateSettings(
      NotificationSettingsEntity next) async {
    settings = next;
    return settings;
  }
}

NotificationEntity _note({
  required int id,
  required String title,
  NotificationCategory category = NotificationCategory.system,
  bool isRead = false,
  String body = '',
}) =>
    NotificationEntity(
      id: id,
      title: title,
      body: body,
      category: category,
      isRead: isRead,
      createdAt: DateTime(2026, 10, 15, 10, 0),
    );

void main() {
  Future<FakeNotificationRepository> pumpFeed(
    WidgetTester tester,
    List<NotificationEntity> feed, {
    int unread = 0,
  }) async {
    final repository = FakeNotificationRepository(feed, unread: unread);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const NotificationListPage(),
    ),
      ),
    );
    await tester.pumpAndSettle();
    return repository;
  }

  testWidgets('shows an empty state with no notifications', (tester) async {
    await pumpFeed(tester, const []);

    expect(find.text('No notifications yet'), findsOneWidget);
  });

  testWidgets('renders the feed with an unread badge', (tester) async {
    await pumpFeed(
      tester,
      [_note(id: 1, title: 'Overdue bill'), _note(id: 2, title: 'Low stock')],
      unread: 2,
    );

    expect(find.text('Overdue bill'), findsOneWidget);
    expect(find.text('Low stock'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('marks one notification read on tap', (tester) async {
    final repository = await pumpFeed(
      tester,
      [_note(id: 5, title: 'Overdue bill')],
      unread: 1,
    );

    await tester.tap(find.text('Overdue bill'));
    await tester.pumpAndSettle();

    expect(repository.markedRead, contains(5));
  });

  testWidgets('mark-all-read is disabled when nothing is unread',
      (tester) async {
    await pumpFeed(tester, [_note(id: 1, title: 'Seen', isRead: true)]);

    final button = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.done_all),
        matching: find.byType(IconButton),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('mark-all-read delegates when there is something unread',
      (tester) async {
    final repository = await pumpFeed(
      tester,
      [_note(id: 1, title: 'Unread')],
      unread: 1,
    );

    await tester.tap(find.byIcon(Icons.done_all));
    await tester.pumpAndSettle();

    expect(repository.markAllReadCalls, 1);
    expect(find.text('1 marked read'), findsOneWidget);
  });

  testWidgets('unreadOnly filter hides read notifications', (tester) async {
    await pumpFeed(
      tester,
      [
        _note(id: 1, title: 'Unread one'),
        _note(id: 2, title: 'Already read', isRead: true),
      ],
      unread: 1,
    );

    expect(find.text('Unread one'), findsOneWidget);
    expect(find.text('Already read'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.filter_alt_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Unread one'), findsOneWidget);
    expect(find.text('Already read'), findsNothing);
  });

  // --- Settings page -------------------------------------------------------

  Future<FakeNotificationRepository> pumpSettings(WidgetTester tester) async {
    final repository = FakeNotificationRepository([]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const NotificationSettingsPage(),
    ),
      ),
    );
    await tester.pumpAndSettle();
    return repository;
  }

  testWidgets('settings lists the master switch and every category',
      (tester) async {
    await pumpSettings(tester);

    expect(find.text('Push notifications'), findsOneWidget);
    expect(find.text('Enable push'), findsOneWidget);
    expect(find.text('Reminders'), findsOneWidget);
    expect(find.text('Low stock'), findsOneWidget);
    expect(find.text('Payment due'), findsOneWidget);
  });

  testWidgets('settings explains that the in-app feed is always written',
      (tester) async {
    await pumpSettings(tester);

    expect(
      find.textContaining('always recorded'),
      findsOneWidget,
    );
  });

  testWidgets('toggling a category persists through the repository',
      (tester) async {
    final repository = await pumpSettings(tester);

    final toggle = find.ancestor(
      of: find.text('Reminders'),
      matching: find.byType(SwitchListTile),
    );
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(repository.settings.reminderEnabled, isFalse);
  });

  testWidgets('turning push off disables the category switches',
      (tester) async {
    await pumpSettings(tester);

    final master = find.ancestor(
      of: find.text('Enable push'),
      matching: find.byType(SwitchListTile),
    );
    await tester.tap(master);
    await tester.pumpAndSettle();

    final reminder = tester.widget<SwitchListTile>(
      find.ancestor(
        of: find.text('Reminders'),
        matching: find.byType(SwitchListTile),
      ),
    );
    expect(reminder.onChanged, isNull);
  });
}
