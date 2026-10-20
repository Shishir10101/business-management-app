import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/khata_snackbars.dart';
import '../../domain/entities/notification_entity.dart';
import '../providers/notification_providers.dart';
import '../../../../core/utils/nepali_date_utils.dart';
import '../../../../l10n/app_localizations.dart';

/// The in-app notification feed: newest first, grouped by read state.
///
/// Reading is a per-item action; "mark all read" is a single call that the
/// server applies to every unread row for this user.
class NotificationListPage extends ConsumerStatefulWidget {
  const NotificationListPage({super.key});

  @override
  ConsumerState<NotificationListPage> createState() =>
      _NotificationListPageState();
}

class _NotificationListPageState extends ConsumerState<NotificationListPage> {
  NotificationFilter _filter = const NotificationFilter();

  NotificationFilter get _current => _filter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);


    final feedAsync = ref.watch(notificationListProvider(_filter));
    final unread = ref.watch(unreadNotificationCountProvider).valueOrNull ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(l10n.notifications),
            if (unread > 0) ...[
              const SizedBox(width: 8),
              _UnreadBadge(count: unread),
            ],
          ],
        ),
        actions: [
          IconButton(
            tooltip: _filter.unreadOnly ? l10n.showingUnread : l10n.showingAll,
            icon: Icon(_filter.unreadOnly
                ? Icons.filter_alt
                : Icons.filter_alt_outlined),
            onPressed: () => setState(() {
              _filter = _filter.copyWith(unreadOnly: !_filter.unreadOnly);
            }),
          ),
          PopupMenuButton<NotificationCategory?>(
            tooltip: l10n.filterByCategory,
            icon: const Icon(Icons.tune),
            onSelected: (value) => setState(() {
              _filter = value == null
                  ? _filter.copyWith(clearCategory: true)
                  : _filter.copyWith(category: value);
            }),
            itemBuilder: (context) => [
              PopupMenuItem(value: null, child: Text(l10n.filterAllCategories)),
              ...NotificationCategory.values.map(
                (c) => PopupMenuItem(value: c, child: Text(c.label(l10n))),
              ),
            ],
          ),
          IconButton(
            tooltip: l10n.markAllRead,
            icon: const Icon(Icons.done_all),
            onPressed: unread == 0 ? null : _markAllRead,
          ),
          IconButton(
            tooltip: l10n.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/notifications/settings'),
          ),
        ],
      ),
      body: feedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          message: l10n.couldNotLoadX(l10n.notifications, '$error'),
          onRetry: () => ref.invalidate(notificationListProvider(_current)),
        ),
        data: (items) {
          if (items.isEmpty) {
            return _EmptyView(
              message: _filter.unreadOnly || _filter.category != null
                  ? l10n.nothingMatchesFilter
                  : l10n.noNotifications,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => refreshNotifications(ref),
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) =>
                  _NotificationTile(item: items[index]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _markAllRead() async {
    final l10n = AppLocalizations.of(context);
    try {
      final count = await markAllNotificationsRead(ref);
      if (mounted) {
        showInfoSnackBar(
          context,
          count == 0 ? l10n.nothingToMark : '$count marked read',
        );
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, '$e');
    }
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.item});

  final NotificationEntity item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);


    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(child: Icon(_iconFor(item.category), size: 20)),
        title: Text(
          item.title,
          style: item.isRead
              ? null
              : theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.body.isNotEmpty) Text(item.body),
            const SizedBox(height: 4),
            Text(
              '${item.category.label(l10n)} · ${_relative(item.createdAt)}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        isThreeLine: item.body.isNotEmpty,
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            try {
              if (value == 'read') {
                await markNotificationRead(ref, item.id);
              } else if (value == 'delete') {
                await deleteNotification(ref, item.id);
              }
            } catch (e) {
              if (context.mounted) showErrorSnackBar(context, '$e');
            }
          },
          itemBuilder: (context) => [
            if (!item.isRead)
              PopupMenuItem(value: 'read', child: Text(l10n.markRead)),
            PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
          ],
        ),
        onTap: item.isRead
            ? null
            : () async {
                try {
                  await markNotificationRead(ref, item.id);
                } catch (e) {
                  if (context.mounted) showErrorSnackBar(context, '$e');
                }
              },
      ),
    );
  }

  static IconData _iconFor(NotificationCategory category) => switch (category) {
        NotificationCategory.reminder => Icons.alarm,
        NotificationCategory.lowStock => Icons.inventory_2_outlined,
        NotificationCategory.paymentDue => Icons.payments_outlined,
        NotificationCategory.backup => Icons.backup_outlined,
        NotificationCategory.system => Icons.info_outline,
      };
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.notifications_none, size: 48),
            const SizedBox(height: 12),
            Text(message),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: Text(l10n.retry)),
          ],
        ),
      ),
    );
  }
}

/// Compact "3h ago" style label. The API sends Nepal local timestamps.
String _relative(DateTime value) {
  final diff = DateTime.now().difference(value);
  if (diff.isNegative) return 'just now';
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return formatDisplayDate(value);
}

String _two(int value) => value.toString().padLeft(2, '0');
