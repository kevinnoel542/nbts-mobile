import 'package:flutter/material.dart';
import 'package:nbts/core/localization/app_language.dart';
import 'package:nbts/core/api/api_client.dart';
import 'package:nbts/core/api/service_locator.dart';
import 'package:nbts/core/data/models/appointment.dart';
import 'package:nbts/core/routes/app_routes.dart';
import 'package:nbts/core/theme/app_tokens.dart';
import 'package:nbts/core/widgets/app_card.dart';
import 'package:nbts/core/widgets/empty_state.dart';
import 'package:nbts/core/widgets/section_header.dart';
import 'package:nbts/core/widgets/status_pill.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  late Future<Appointment?> _upcomingFuture;
  late Future<List<Appointment>> _appointmentsFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _upcomingFuture = Services.instance.appointments.fetchUpcoming().catchError(
      (_) async => null,
    );
    _appointmentsFuture = Services.instance.appointments.fetchAll();
  }

  Future<void> _refresh() async {
    setState(_load);
    await Future.wait([_upcomingFuture, _appointmentsFuture]);
  }

  Future<void> _reschedule(Appointment appointment) async {
    final changed = await Navigator.pushNamed(
      context,
      AppRoutes.bookAppointment,
      arguments: appointment,
    );
    if (changed == true && mounted) {
      await _refresh();
    }
  }

  Future<void> _cancel(Appointment appointment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.t('appointments.cancelTitle')),
        content: Text(context.t('appointments.cancelMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.t('appointments.keep')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.t('appointments.cancelAppointment')),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await Services.instance.appointments.cancel(appointment.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('appointments.cancelled'))),
      );
      await _refresh();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.firstError())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(context.t('appointments.title')),
      ),
      body: FutureBuilder<List<Appointment>>(
        future: _appointmentsFuture,
        builder: (context, listSnap) {
          if (listSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (listSnap.hasError) {
            final message = listSnap.error is ApiException
                ? (listSnap.error as ApiException).message
                : context.t('appointments.unavailable');
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  EmptyState(
                    icon: Icons.event_busy_outlined,
                    title: context.t('appointments.unavailable'),
                    message: message,
                  ),
                ],
              ),
            );
          }

          final appointments = listSnap.data ?? const <Appointment>[];
          return FutureBuilder<Appointment?>(
            future: _upcomingFuture,
            builder: (context, upcomingSnap) {
              final upcoming = upcomingSnap.data;
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xxl + AppSpacing.lg,
                  ),
                  children: [
                    SectionHeader(context.t('appointments.next')),
                    if (upcoming == null)
                      AppCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: EmptyState(
                          icon: Icons.event_busy_outlined,
                          title: context.t('appointments.noneBooked'),
                          message: context.t('appointments.noneBookedMessage'),
                        ),
                      )
                    else
                      _UpcomingCard(
                        appointment: upcoming,
                        onReschedule: () => _reschedule(upcoming),
                        onCancel: () => _cancel(upcoming),
                      ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton.icon(
                      onPressed: upcoming == null
                          ? () => Navigator.pushNamed(
                              context,
                              AppRoutes.bookAppointment,
                            )
                          : () => _reschedule(upcoming),
                      icon: Icon(
                        upcoming == null
                            ? Icons.add_rounded
                            : Icons.edit_calendar_outlined,
                      ),
                      label: Text(
                        upcoming == null
                            ? context.t('appointments.bookNew')
                            : context.t('appointments.change'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SectionHeader(context.t('appointments.all')),
                    if (appointments.isEmpty)
                      AppCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: EmptyState(
                          icon: Icons.calendar_month_outlined,
                          title: context.t('appointments.noneYet'),
                          message: context.t('appointments.noneYetMessage'),
                        ),
                      )
                    else
                      for (final appointment in appointments)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _AppointmentCard(
                            appointment: appointment,
                            onReschedule: () => _reschedule(appointment),
                            onCancel: () => _cancel(appointment),
                          ),
                        ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({
    required this.appointment,
    required this.onReschedule,
    required this.onCancel,
  });

  final Appointment appointment;
  final VoidCallback onReschedule;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.t('appointments.status'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              StatusPill(
                label: _statusLabel(context, appointment.status),
                icon: _statusIcon(appointment.status),
                kind: _statusKind(appointment.status),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _formatDateTime(appointment.scheduledAt),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _text(
              appointment.centerName,
              fallback: context.t('appointments.centerPending'),
            ),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _canManage(appointment) ? onReschedule : null,
                  child: FittedBox(child: Text(context.t('appointments.reschedule'))),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _canManage(appointment) ? onCancel : null,
                  child: FittedBox(child: Text(context.t('appointments.cancel'))),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.onReschedule,
    required this.onCancel,
  });

  final Appointment appointment;
  final VoidCallback onReschedule;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: AppRadius.chip,
            ),
            child: Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDateTime(appointment.scheduledAt),
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _text(
                    appointment.centerName,
                    fallback: context.t('appointments.centerPending'),
                  ),
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            enabled: _canManage(appointment),
            onSelected: (value) {
              if (value == 'reschedule') onReschedule();
              if (value == 'cancel') onCancel();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'reschedule',
                child: FittedBox(child: Text(context.t('appointments.reschedule'))),
              ),
              PopupMenuItem(
                value: 'cancel',
                child: FittedBox(child: Text(context.t('appointments.cancel'))),
              ),
            ],
            child: StatusPill(
              label: _statusLabel(context, appointment.status),
              kind: _statusKind(appointment.status),
            ),
          ),
        ],
      ),
    );
  }
}

String _text(String? value, {required String fallback}) {
  if (value == null || value.trim().isEmpty) return fallback;
  return value;
}

String _formatDateTime(DateTime? date) {
  if (date == null) {
    return AppStrings.text(
      'appointments.datePending',
      LanguageController.code.value,
    );
  }
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hh = date.hour.toString().padLeft(2, '0');
  final mm = date.minute.toString().padLeft(2, '0');
  return '${months[date.month - 1]} ${date.day}, ${date.year}  $hh:$mm';
}

String _statusLabel(BuildContext context, String? status) {
  final value = status?.toLowerCase().trim();
  return switch (value) {
    'pending' => context.t('status.pendingConfirmation'),
    'confirmed' => context.t('status.confirmed'),
    'rescheduled' => context.t('status.rescheduled'),
    'cancelled' || 'canceled' => context.t('status.cancelled'),
    'completed' => context.t('status.completed'),
    'missed' => context.t('status.missed'),
    _ => context.t('status.upcoming'),
  };
}

StatusKind _statusKind(String? status) {
  final value = status?.toLowerCase().trim();
  return switch (value) {
    'confirmed' || 'completed' => StatusKind.success,
    'pending' || 'rescheduled' => StatusKind.warning,
    'cancelled' || 'canceled' || 'missed' => StatusKind.neutral,
    _ => StatusKind.neutral,
  };
}

IconData _statusIcon(String? status) {
  final value = status?.toLowerCase().trim();
  return switch (value) {
    'confirmed' || 'completed' => Icons.event_available_outlined,
    'pending' || 'rescheduled' => Icons.schedule_rounded,
    'cancelled' || 'canceled' || 'missed' => Icons.event_busy_outlined,
    _ => Icons.event_available_outlined,
  };
}

bool _canManage(Appointment appointment) {
  final status = appointment.status?.toLowerCase().trim();
  return status != 'completed' && status != 'cancelled';
}

