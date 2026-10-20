import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/notification_entity.dart';

/// The active feed filter. Part of the provider key so switching a filter
/// fetches (and caches) independently instead of reusing stale rows.
class NotificationFilter {
  final bool unreadOnly;
  final NotificationCategory? category;

  const NotificationFilter({this.unreadOnly = false, this.category});

  NotificationFilter copyWith({
    bool? unreadOnly,
    NotificationCategory? category,
    bool clearCategory = false,
  }) =>
      NotificationFilter(
        unreadOnly: unreadOnly ?? this.unreadOnly,
        category: clearCategory ? null : (category ?? this.category),
      );

  @override
  bool operator ==(Object other) =>
      other is NotificationFilter &&
      other.unreadOnly == unreadOnly &&
      other.category == category;

  @override
  int get hashCode => Object.hash(unreadOnly, category);
}

/// Server-synced notification feed for the current user, filtered.
final notificationListProvider =
    FutureProvider.family<List<NotificationEntity>, NotificationFilter>(
        (ref, filter) async {
  return ref.read(notificationRepositoryProvider).getNotifications(
        unreadOnly: filter.unreadOnly,
        category: filter.category,
      );
});

/// Unread badge count (cheap poll target for the home page).
final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  return ref.read(notificationRepositoryProvider).getUnreadCount();
});

/// Per-user push preferences.
final notificationSettingsProvider =
    FutureProvider<NotificationSettingsEntity>((ref) async {
  return ref.read(notificationRepositoryProvider).getSettings();
});

/// Registered push devices for the current user.
final deviceListProvider = FutureProvider<List<DeviceEntity>>((ref) async {
  return ref.read(notificationRepositoryProvider).getDevices();
});

/// Marks one notification read and refreshes the badge.
Future<void> markNotificationRead(WidgetRef ref, int id) async {
  await ref.read(notificationRepositoryProvider).markRead(id);
  refreshNotifications(ref);
}

/// Marks everything read.
Future<int> markAllNotificationsRead(WidgetRef ref) async {
  final count = await ref.read(notificationRepositoryProvider).markAllRead();
  refreshNotifications(ref);
  return count;
}

Future<void> deleteNotification(WidgetRef ref, int id) async {
  await ref.read(notificationRepositoryProvider).delete(id);
  refreshNotifications(ref);
}

/// Refreshes the feed (every filter) and the badge after a mutation.
void refreshNotifications(WidgetRef ref) {
  ref.invalidate(notificationListProvider);
  ref.invalidate(unreadNotificationCountProvider);
}
