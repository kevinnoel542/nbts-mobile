import 'package:flutter/material.dart';
import 'package:nbts/core/api/api_client.dart';
import 'package:nbts/core/api/service_locator.dart';
import 'package:nbts/core/data/models/donation_center.dart';
import 'package:nbts/core/data/models/json_utils.dart';
import 'package:nbts/core/data/models/user_notification.dart';
import 'package:nbts/core/localization/app_language.dart';
import 'package:nbts/core/notifications/notification_counter.dart';
import 'package:nbts/core/routes/app_routes.dart';
import 'package:nbts/core/theme/app_tokens.dart';
import 'package:nbts/core/widgets/app_card.dart';
import 'package:nbts/core/widgets/empty_state.dart';

enum _NotificationFilter { all, unread, appointments, urgent }

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<UserNotification>> _future;
  List<UserNotification> _notifications = const <UserNotification>[];
  _NotificationFilter _filter = _NotificationFilter.all;

  @override
  void initState() {
    super.initState();
    _future = _fetchNotifications();
  }

  Future<List<UserNotification>> _fetchNotifications() async {
    final list = await Services.instance.notifications.fetchAll();
    _notifications = list;
    setNotificationCount(list.where((n) => !n.read).length);
    return list;
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _fetchNotifications();
    });
    await _future;
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
    final action = _actionFor(context, notification);
    if (!notification.read && notification.id != 0) {
      try {
        await Services.instance.notifications.markRead(notification.id);
        final nextCount = notificationCount.value - 1;
        setNotificationCount(nextCount < 0 ? 0 : nextCount);
      } catch (_) {}
    }
    if (!mounted) return;

    final shouldOpenAction = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final textTheme = Theme.of(sheetContext).textTheme;
        return SafeArea(
          child: Padding(
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
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (notification.body.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(notification.body),
                ],
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(sheetContext, false),
                      child: Text(sheetContext.t('common.done')),
                    ),
                    if (action != null)
                      FilledButton.icon(
                        onPressed: () => Navigator.pop(sheetContext, true),
                        icon: Icon(action.icon, size: 18),
                        label: Text(action.label),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    if (shouldOpenAction == true && action != null) {
      await Navigator.pushNamed(
        context,
        action.route,
        arguments: action.arguments,
      );
    }
    if (mounted) await _refresh();
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

  List<UserNotification> _visibleNotifications(
    List<UserNotification> notifications,
  ) {
    return notifications
        .where((notification) {
          return switch (_filter) {
            _NotificationFilter.all => true,
            _NotificationFilter.unread => !notification.read,
            _NotificationFilter.appointments => _isAppointment(notification),
            _NotificationFilter.urgent => _isUrgent(notification),
          };
        })
        .toList(growable: false);
  }

  _NotificationAction? _actionFor(
    BuildContext context,
    UserNotification notification,
  ) {
    final target = _actionTarget(notification);
    final center = _centerFromData(context, notification);

    if (_isUrgent(notification)) {
      if (center != null) {
        return _NotificationAction(
          label: context.t('notifications.bookDonation'),
          route: AppRoutes.bookAppointment,
          arguments: center,
          icon: Icons.event_available_outlined,
        );
      }
      return _NotificationAction(
        label: context.t('notifications.findCenters'),
        route: AppRoutes.centers,
        icon: Icons.local_hospital_outlined,
      );
    }

    if (target.contains('book') || target.contains('slot')) {
      return _NotificationAction(
        label: context.t('notifications.bookDonation'),
        route: AppRoutes.bookAppointment,
        arguments: center,
        icon: Icons.event_available_outlined,
      );
    }

    if (target.contains('appointment') || target.contains('miadi')) {
      return _NotificationAction(
        label: context.t('notifications.viewAppointments'),
        route: AppRoutes.appointments,
        icon: Icons.event_note_outlined,
      );
    }

    if (target.contains('donor-card') ||
        target.contains('donor_card') ||
        target.contains('card')) {
      return _NotificationAction(
        label: context.t('notifications.openCard'),
        route: AppRoutes.donorCard,
        icon: Icons.qr_code_rounded,
      );
    }

    if (target.contains('profile') || target.contains('wasifu')) {
      return _NotificationAction(
        label: context.t('notifications.openProfile'),
        route: AppRoutes.profile,
        icon: Icons.person_outline_rounded,
      );
    }

    if (target.contains('center') ||
        target.contains('centre') ||
        target.contains('blood-bank') ||
        target.contains('blood_bank')) {
      return _NotificationAction(
        label: center == null
            ? context.t('notifications.findCenters')
            : context.t('notifications.bookDonation'),
        route: center == null ? AppRoutes.centers : AppRoutes.bookAppointment,
        arguments: center,
        icon: center == null
            ? Icons.local_hospital_outlined
            : Icons.event_available_outlined,
      );
    }

    if (target.contains('campaign')) {
      return _NotificationAction(
        label: center == null
            ? context.t('notifications.findCenters')
            : context.t('notifications.bookDonation'),
        route: center == null ? AppRoutes.centers : AppRoutes.bookAppointment,
        arguments: center,
        icon: center == null
            ? Icons.local_hospital_outlined
            : Icons.event_available_outlined,
      );
    }

    if (target.contains('history') ||
        target.contains('record') ||
        target.contains('donation')) {
      return _NotificationAction(
        label: context.t('notifications.openHistory'),
        route: AppRoutes.history,
        icon: Icons.history_rounded,
      );
    }

    return null;
  }

  DonationCenter? _centerFromData(
    BuildContext context,
    UserNotification notification,
  ) {
    final data = notification.data;
    final nested =
        readObject(data, 'center') ??
        readObject(data, 'blood_center') ??
        readObject(data, 'donation_center');
    final centerId =
        readInt(data, [
          'center_id',
          'blood_center_id',
          'donation_center_id',
          'preferred_center_id',
        ]) ??
        readInt(nested, ['id', 'center_id']);
    if (centerId == null || centerId <= 0) return null;

    final name =
        readString(data, [
          'center_name',
          'blood_center_name',
          'donation_center_name',
        ]) ??
        readString(nested, ['name', 'center_name', 'title']) ??
        context.t('book.donationCenter');

    return DonationCenter(
      id: centerId,
      name: name,
      address:
          readString(data, ['center_address', 'address', 'location']) ??
          readString(nested, ['address', 'location', 'full_address']),
      phone:
          readString(data, ['center_phone', 'phone']) ??
          readString(nested, ['phone', 'phone_number', 'contact']),
      hours:
          readString(data, ['center_hours', 'hours', 'opening_hours']) ??
          readString(nested, ['hours', 'opening_hours', 'working_hours']),
    );
  }

  bool _isAppointment(UserNotification notification) {
    final target = _actionTarget(notification);
    return target.contains('appointment') || target.contains('miadi');
  }

  bool _isUrgent(UserNotification notification) {
    final target = _actionTarget(notification);
    final urgent = readBool(notification.data, [
      'urgent',
      'is_urgent',
      'priority_urgent',
    ]);
    return urgent == true ||
        target.contains('urgent') ||
        target.contains('emergency') ||
        target.contains('stock');
  }

  String _actionTarget(UserNotification notification) {
    final actionUrl = notification.actionUrl;
    final data = notification.data;
    final parts = <String>[
      notification.title,
      notification.body,
      notification.type ?? '',
      actionUrl ?? '',
      readString(data, [
            'type',
            'category',
            'action',
            'route',
            'screen',
            'path',
            'url',
            'action_url',
          ]) ??
          '',
    ];

    if (actionUrl != null) {
      final uri = Uri.tryParse(actionUrl);
      if (uri != null) {
        parts
          ..add(uri.host)
          ..add(uri.path)
          ..add(uri.query);
      }
    }

    return parts.join(' ').toLowerCase();
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
                ? (snapshot.error as ApiException).safeMessage
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
          final visible = _visibleNotifications(notifications);
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
                if (notifications.isNotEmpty) ...[
                  _FilterBar(
                    selected: _filter,
                    onChanged: (filter) => setState(() => _filter = filter),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (notifications.isEmpty)
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: EmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: context.t('notifications.empty'),
                      message: context.t('notifications.emptyMessage'),
                    ),
                  )
                else if (visible.isEmpty)
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: EmptyState(
                      icon: Icons.filter_list_off_rounded,
                      title: context.t('notifications.noFiltered'),
                      message: context.t('notifications.noFilteredMessage'),
                    ),
                  )
                else
                  for (final entry in visible.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Dismissible(
                        key: ValueKey(
                          'notification-${entry.$2.id}-${entry.$1}',
                        ),
                        direction: DismissDirection.endToStart,
                        background: _DismissBackground(
                          label: context.t('notifications.delete'),
                        ),
                        confirmDismiss: (_) => _deleteNotification(entry.$2),
                        onDismissed: (_) => _removeNotification(entry.$2),
                        child: _NotificationTile(
                          notification: entry.$2,
                          onTap: () => _open(entry.$2),
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

class _NotificationAction {
  const _NotificationAction({
    required this.label,
    required this.route,
    required this.icon,
    this.arguments,
  });

  final String label;
  final String route;
  final IconData icon;
  final Object? arguments;
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onChanged});

  final _NotificationFilter selected;
  final ValueChanged<_NotificationFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = [
      (filter: _NotificationFilter.all, label: context.t('notifications.all')),
      (
        filter: _NotificationFilter.unread,
        label: context.t('notifications.unread'),
      ),
      (
        filter: _NotificationFilter.appointments,
        label: context.t('notifications.appointments'),
      ),
      (
        filter: _NotificationFilter.urgent,
        label: context.t('notifications.urgent'),
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ChoiceChip(
                label: Text(item.label),
                selected: selected == item.filter,
                onSelected: (_) => onChanged(item.filter),
                selectedColor: scheme.primary.withValues(alpha: 0.16),
                backgroundColor: scheme.surfaceContainerHighest.withValues(
                  alpha: 0.55,
                ),
                labelStyle: TextStyle(
                  color: selected == item.filter
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
                side: BorderSide(
                  color: selected == item.filter
                      ? scheme.primary.withValues(alpha: 0.45)
                      : scheme.outlineVariant,
                ),
              ),
            ),
        ],
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
