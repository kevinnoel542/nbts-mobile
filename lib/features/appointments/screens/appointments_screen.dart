import 'package:flutter/material.dart';
import 'package:nbts/core/data/app_data.dart';
import 'package:nbts/core/routes/app_routes.dart';
import 'package:nbts/core/theme/app_tokens.dart';
import 'package:nbts/core/widgets/app_card.dart';
import 'package:nbts/core/widgets/empty_state.dart';
import 'package:nbts/core/widgets/section_header.dart';
import 'package:nbts/core/widgets/status_pill.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final appointment = AppData.nextAppointment;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Appointments'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          const SectionHeader('Next appointment'),
          if (appointment == null)
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: const EmptyState(
                icon: Icons.event_busy_outlined,
                title: 'No appointment booked',
                message:
                    'Book a donation to see your upcoming visit details here.',
              ),
            )
          else
            _UpcomingCard(scheme: scheme, appointment: appointment),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.bookAppointment),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Book new donation'),
          ),
          const SizedBox(height: AppSpacing.xl),
          SectionHeader(
            'Nearby centers',
            action: TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.centers),
              child: const Text('See all'),
            ),
          ),
          if (AppData.centers.isEmpty)
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: const EmptyState(
                icon: Icons.place_outlined,
                title: 'No centers available',
                message:
                    'Donation centers will appear once they are loaded from NBTS.',
              ),
            )
          else
            for (final center in AppData.centers)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _CenterCard(center: center),
              ),
        ],
      ),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.scheme, required this.appointment});

  final ColorScheme scheme;
  final String appointment;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Confirmed',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const StatusPill(
                label: 'Upcoming',
                icon: Icons.event_available_outlined,
                kind: StatusKind.success,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            appointment,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppData.preferredCenter,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Reschedule'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CenterCard extends StatelessWidget {
  const _CenterCard({required this.center});

  final DonationCenter center;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      onTap: () =>
          Navigator.pushNamed(context, AppRoutes.bookAppointment),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  center.name,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              StatusPill(
                label: center.isOpen ? 'Open' : 'Closed',
                kind: center.isOpen
                    ? StatusKind.success
                    : StatusKind.neutral,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            center.address,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _Meta(
                icon: Icons.near_me_outlined,
                value: '${center.distanceKm} km',
              ),
              const SizedBox(width: AppSpacing.md),
              _Meta(icon: Icons.schedule_outlined, value: center.hours),
              const SizedBox(width: AppSpacing.md),
              _Meta(icon: Icons.timer_outlined, value: center.waitTime),
            ],
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
