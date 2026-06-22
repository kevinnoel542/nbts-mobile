import 'package:flutter/material.dart';
import 'package:nbts/core/api/service_locator.dart';
import 'package:nbts/core/data/models/appointment.dart';
import 'package:nbts/core/data/models/campaign.dart';
import 'package:nbts/core/data/models/user.dart';
import 'package:nbts/core/routes/app_routes.dart';
import 'package:nbts/core/theme/app_tokens.dart';
import 'package:nbts/core/widgets/app_card.dart';
import 'package:nbts/core/widgets/section_header.dart';
import 'package:nbts/core/widgets/stat_tile.dart';
import 'package:nbts/core/widgets/status_pill.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<User?> _profileFuture;
  late Future<Appointment?> _upcomingFuture;
  late Future<List<Campaign>> _campaignsFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final s = Services.instance;
    _profileFuture = () async {
      try {
        return await s.profile.fetch();
      } catch (_) {
        return null;
      }
    }();
    _upcomingFuture =
        s.appointments.fetchUpcoming().catchError((_) async => null);
    _campaignsFuture =
        s.campaigns.fetchAll().catchError((_) async => <Campaign>[]);
  }

  Future<void> _refresh() async {
    setState(_load);
    await Future.wait([_profileFuture, _upcomingFuture, _campaignsFuture]);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Icon(Icons.water_drop_rounded, size: 20, color: scheme.primary),
            const SizedBox(width: 8),
            const Text('NBTS'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_rounded),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.donorCard),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<User?>(
          future: _profileFuture,
          builder: (context, profileSnap) {
            final user = profileSnap.data;
            return FutureBuilder<Appointment?>(
              future: _upcomingFuture,
              builder: (context, apptSnap) {
                final upcoming = apptSnap.data;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  children: [
                    _Greeting(scheme: scheme, user: user),
                    const SizedBox(height: AppSpacing.lg),
                    const _UrgentRequestBanner(),
                    const SizedBox(height: AppSpacing.md),
                    _EligibilityCard(scheme: scheme, user: user),
                    const SizedBox(height: AppSpacing.md),
                    _NextAppointmentCard(
                      scheme: scheme,
                      appointment: upcoming,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _StatsRow(user: user),
                    const SizedBox(height: AppSpacing.xl),
                    const SectionHeader('Quick actions'),
                    _QuickActions(),
                    const SizedBox(height: AppSpacing.xl),
                    _ImpactCard(scheme: scheme, user: user),
                    const SizedBox(height: AppSpacing.xl),
                    SectionHeader(
                      'For you',
                      action: TextButton(
                        onPressed: () {},
                        child: const Text('See all'),
                      ),
                    ),
                    FutureBuilder<List<Campaign>>(
                      future: _campaignsFuture,
                      builder: (context, snap) {
                        final list = snap.data ?? const <Campaign>[];
                        if (list.isEmpty) {
                          return _ArticlesPlaceholder(scheme: scheme);
                        }
                        return Column(
                          children: [
                            for (final c in list)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.md,
                                ),
                                child: _CampaignTile(campaign: c),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
String _formatDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

String _formatDateTime(DateTime d) {
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  return '${_formatDate(d)}  $hh:$mm';
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.scheme, required this.user});

  final ColorScheme scheme;
  final User? user;

  @override
  Widget build(BuildContext context) {
    final name = user?.name.isNotEmpty == true ? user!.name : 'Welcome donor';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome',
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          name,
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }
}

class _EligibilityCard extends StatelessWidget {
  const _EligibilityCard({required this.scheme, required this.user});

  final ColorScheme scheme;
  final User? user;

  @override
  Widget build(BuildContext context) {
    final nextDate = user?.nextEligibleDate;
    final now = DateTime.now();
    final isEligible = nextDate == null || !nextDate.isAfter(now);
    final dateText = nextDate == null
        ? 'Pending medical verification'
        : isEligible
            ? 'Eligible to donate'
            : 'Next eligible: ${_formatDate(nextDate)}';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Eligibility',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              StatusPill(
                label: isEligible ? 'Eligible' : 'Pending',
                icon: isEligible
                    ? Icons.check_circle_outline_rounded
                    : Icons.schedule_rounded,
                kind: isEligible ? StatusKind.success : StatusKind.neutral,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            dateText,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.bookAppointment,
                  ),
                  icon: const Icon(Icons.calendar_today_rounded, size: 18),
                  label: const Text('Book donation'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.donorCard),
                  child: const Text('Donor card'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.user});
  final User? user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: StatTile(
              icon: Icons.water_drop_outlined,
              value: '${user?.totalDonations ?? 0}',
              label: 'Donations',
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: StatTile(
              icon: Icons.local_drink_outlined,
              value: '${user?.totalVolumeMl ?? 0}',
              unit: 'mL',
              label: 'Volume',
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = <_QuickActionData>[
      _QuickActionData(
        icon: Icons.place_outlined,
        label: 'Find centers',
        route: AppRoutes.centers,
      ),
      _QuickActionData(
        icon: Icons.history_rounded,
        label: 'History',
        route: AppRoutes.history,
      ),
      _QuickActionData(
        icon: Icons.qr_code_rounded,
        label: 'Donor card',
        route: AppRoutes.donorCard,
      ),
      _QuickActionData(
        icon: Icons.person_outline_rounded,
        label: 'Profile',
        route: AppRoutes.profile,
      ),
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 0.95,
      children: [
        for (final item in items)
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.sm),
            onTap: () => Navigator.pushNamed(context, item.route),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item.icon,
                  size: 22,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(height: 8),
                Text(
                  item.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _QuickActionData {
  const _QuickActionData({
    required this.icon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String route;
}

class _CampaignTile extends StatelessWidget {
  const _CampaignTile({required this.campaign});

  final Campaign campaign;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final category = (campaign.category ?? 'Campaign').toUpperCase();
    final summary = campaign.summary ?? '';
    final isUrgent = campaign.urgent == true;
    return AppCard(
      onTap: () {},
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isUrgent
                  ? AppStatus.warning.withValues(alpha: 0.10)
                  : scheme.surfaceContainerHigh,
              borderRadius: AppRadius.chip,
            ),
            child: Icon(
              isUrgent
                  ? Icons.campaign_rounded
                  : Icons.local_hospital_outlined,
              size: 20,
              color: isUrgent ? AppStatus.warning : scheme.onSurface,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  campaign.title,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                if (summary.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _ArticlesPlaceholder extends StatelessWidget {
  const _ArticlesPlaceholder({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(
            Icons.article_outlined,
            size: 20,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'No campaigns available right now.',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _UrgentRequestBanner extends StatelessWidget {
  const _UrgentRequestBanner();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => Navigator.pushNamed(context, AppRoutes.centers),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppStatus.warning.withValues(alpha: 0.10),
              borderRadius: AppRadius.chip,
            ),
            child: const Icon(
              Icons.campaign_rounded,
              size: 20,
              color: AppStatus.warning,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StatusPill(
                  label: 'Urgent',
                  kind: StatusKind.warning,
                ),
                const SizedBox(height: 6),
                Text(
                  'Awaiting NBTS urgent request feed',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _NextAppointmentCard extends StatelessWidget {
  const _NextAppointmentCard({
    required this.scheme,
    required this.appointment,
  });

  final ColorScheme scheme;
  final Appointment? appointment;

  @override
  Widget build(BuildContext context) {
    final next = appointment;
    final label = next == null
        ? 'No upcoming appointment'
        : next.scheduledAt != null
            ? _formatDateTime(next.scheduledAt!)
            : (next.centerName ?? 'Scheduled');
    return AppCard(
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
              Icons.event_available_outlined,
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
                  'Next appointment',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                if (next?.centerName != null && next?.scheduledAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    next!.centerName!,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.bookAppointment),
            child: Text(next == null ? 'Book' : 'Manage'),
          ),
        ],
      ),
    );
  }
}

class _ImpactCard extends StatelessWidget {
  const _ImpactCard({required this.scheme, required this.user});

  final ColorScheme scheme;
  final User? user;

  @override
  Widget build(BuildContext context) {
    const goal = 16;
    final donations = user?.totalDonations ?? 0;
    final progress = (donations / goal).clamp(0.0, 1.0);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.favorite_outline_rounded,
                size: 18,
                color: scheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Your impact',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              Text(
                '$donations / $goal',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: AppRadius.pill,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation(scheme.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Donations toward the next loyalty tier.',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
