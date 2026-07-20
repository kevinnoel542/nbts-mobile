import 'package:flutter/material.dart';
import 'package:nbts/core/localization/app_language.dart';
import 'package:nbts/core/api/api_client.dart';
import 'package:nbts/core/api/service_locator.dart';
import 'package:nbts/core/data/models/user_notification.dart';
import 'package:nbts/core/notifications/notification_counter.dart';
import 'package:nbts/core/theme/app_tokens.dart';
import 'package:nbts/core/widgets/app_card.dart';
import 'package:nbts/core/widgets/empty_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<UserNotification>> _future;
  List<UserNotification> _notifications = const <UserNotification>[];

  @override
  void initState() {
    super.initState();
    _future = Services.instance.notifications.fetchAll();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = Services.instance.notifications.fetchAll();
    });
    final list = await _future;
    _notifications = list;
    setNotificationCount(list.where((n) => !n.read).length);
  }

  Future<void> _markAllRead() async {
    try {
      final count = await Services.instance.notifications.markAllRead();
      setNotificationCount(count);
      await _refresh();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.firstError())));
    }
  }

  Future<void> _open(UserNotification notification) async {
    if (!notification.read && notification.id != 0) {
      try {
        await Services.instance.notifications.markRead(notification.id);
        setNotificationCount(notificationCount.value - 1);
      } catch (_) {}
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(notification.body),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.t('common.done')),
              ),
            ),
          ],
        ),
      ),
    );
    await _refresh();
  }

  Future<bool> _deleteNotification(UserNotification notification) async {
    if (notification.id == 0) return false;
    try {
      await Services.instance.notifications.delete(notification.id);
      return true;
    } on ApiException catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.firstError())));
      return false;
    } catch (_) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('notifications.deleteFailed'))),
      );
      return false;
    }
  }

  void _removeNotification(UserNotification notification) {
    final next = _notifications
        .where((item) => item.id != notification.id)
        .toList(growable: false);
    setState(() {
      _notifications = next;
      _future = Future.value(next);
    });
    setNotificationCount(next.where((n) => !n.read).length);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.t('notifications.deleted'))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('notifications.title')),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: Text(context.t('notifications.markRead')),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: FutureBuilder<List<UserNotification>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : context.t('notifications.loadFailed');
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  EmptyState(
                    icon: Icons.notifications_off_outlined,
                    title: context.t('notifications.unavailable'),
                    message: message,
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data ?? const <UserNotification>[];
          _notifications = notifications;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              children: [
                if (notifications.isEmpty)
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: EmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: context.t('notifications.empty'),
                      message: context.t('notifications.emptyMessage'),
                    ),
                  )
                else
                  for (final notification in notifications)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Dismissible(
                        key: ValueKey('notification-${notification.id}'),
                        direction: DismissDirection.endToStart,
                        background: _DismissBackground(
                          label: context.t('notifications.delete'),
                        ),
                        confirmDismiss: (_) =>
                            _deleteNotification(notification),
                        onDismissed: (_) => _removeNotification(notification),
                        child: _NotificationTile(
                          notification: notification,
                          onTap: () => _open(notification),
                        ),
                      ),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DismissBackground extends StatelessWidget {
  const _DismissBackground({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.error,
        borderRadius: AppRadius.card,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.delete_outline_rounded, color: scheme.onError),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: scheme.onError,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final UserNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final unread = !notification.read;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: unread
                  ? scheme.primary.withValues(alpha: 0.12)
                  : scheme.surfaceContainerHigh,
              borderRadius: AppRadius.chip,
            ),
            child: Icon(
              _iconFor(notification.type),
              size: 20,
              color: unread ? scheme.primary : scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 15,
                          fontWeight: unread
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (unread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                if (notification.body.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String? type) {
    final value = type?.toLowerCase() ?? '';
    if (value.contains('appointment')) return Icons.event_available_outlined;
    if (value.contains('campaign')) return Icons.campaign_outlined;
    if (value.contains('stock') || value.contains('urgent')) {
      return Icons.priority_high_rounded;
    }
    return Icons.notifications_outlined;
  }
}
