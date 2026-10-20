import '../entities/notification_entity.dart';

/// The in-app notification feed, device registration and push settings.
abstract class NotificationRepository {
  /// The current user's notifications, newest first.
  Future<List<NotificationEntity>> getNotifications({
    bool unreadOnly = false,
    NotificationCategory? category,
  });

  /// Unread badge count.
  Future<int> getUnreadCount();

  Future<void> markRead(int id);
  Future<int> markAllRead();
  Future<void> delete(int id);

  /// Registers (or refreshes) this device's push token.
  Future<void> registerDevice({
    required String token,
    required String platform,
  });

  Future<List<DeviceEntity>> getDevices();

  Future<NotificationSettingsEntity> getSettings();
  Future<NotificationSettingsEntity> updateSettings(
      NotificationSettingsEntity settings);
}
