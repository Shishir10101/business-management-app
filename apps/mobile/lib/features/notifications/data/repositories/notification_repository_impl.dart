import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';

/// NotificationRepository backed by the Khata API.
///
/// Timestamps arrive as Nepal local wall-clock values (the API converts from
/// its stored UTC), so they are parsed as-is and rendered without further
/// shifting.
class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._remote);

  final NotificationRemoteDatasource _remote;

  @override
  Future<List<NotificationEntity>> getNotifications({
    bool unreadOnly = false,
    NotificationCategory? category,
  }) async {
    final payload = await _remote.getFeed(
      unreadOnly: unreadOnly,
      category: category?.apiValue,
    );
    final rows = (payload['data'] as List<dynamic>?) ?? const [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(_fromJson)
        .toList(growable: false);
  }

  @override
  Future<int> getUnreadCount() => _remote.getUnreadCount();

  @override
  Future<void> markRead(int id) => _remote.markRead(id);

  @override
  Future<int> markAllRead() => _remote.markAllRead();

  @override
  Future<void> delete(int id) => _remote.delete(id);

  @override
  Future<void> registerDevice({
    required String token,
    required String platform,
  }) async {
    await _remote.registerDevice(token: token, platform: platform);
  }

  @override
  Future<List<DeviceEntity>> getDevices() async {
    final rows = await _remote.getDevices();
    return rows
        .whereType<Map<String, dynamic>>()
        .map((json) => DeviceEntity(
              id: (json['id'] as num).toInt(),
              token: json['token'] as String? ?? '',
              platform: json['platform'] as String? ?? '',
              lastSeenAt: DateTime.tryParse(
                    json['lastSeenAt'] as String? ?? '',
                  ) ??
                  DateTime.now(),
              isActive: json['isActive'] as bool? ?? true,
            ))
        .toList(growable: false);
  }

  @override
  Future<NotificationSettingsEntity> getSettings() async =>
      _settingsFromJson(await _remote.getSettings());

  @override
  Future<NotificationSettingsEntity> updateSettings(
      NotificationSettingsEntity settings) async {
    final payload = await _remote.updateSettings({
      'pushEnabled': settings.pushEnabled,
      'reminderEnabled': settings.reminderEnabled,
      'lowStockEnabled': settings.lowStockEnabled,
      'paymentDueEnabled': settings.paymentDueEnabled,
      'backupEnabled': settings.backupEnabled,
      'systemEnabled': settings.systemEnabled,
    });
    return _settingsFromJson(payload);
  }

  static NotificationEntity _fromJson(Map<String, dynamic> json) =>
      NotificationEntity(
        id: (json['id'] as num).toInt(),
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        category: NotificationCategory.fromApi(json['category'] as String?),
        referenceType: json['referenceType'] as String?,
        referenceId: (json['referenceId'] as num?)?.toInt(),
        isRead: json['isRead'] as bool? ?? false,
        readAt: DateTime.tryParse(json['readAt'] as String? ?? ''),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );

  static NotificationSettingsEntity _settingsFromJson(
          Map<String, dynamic> json) =>
      NotificationSettingsEntity(
        pushEnabled: json['pushEnabled'] as bool? ?? true,
        reminderEnabled: json['reminderEnabled'] as bool? ?? true,
        lowStockEnabled: json['lowStockEnabled'] as bool? ?? true,
        paymentDueEnabled: json['paymentDueEnabled'] as bool? ?? true,
        backupEnabled: json['backupEnabled'] as bool? ?? true,
        systemEnabled: json['systemEnabled'] as bool? ?? true,
      );
}

/// Provider for the notification repository.
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(
      ref.read(notificationRemoteDatasourceProvider));
});
