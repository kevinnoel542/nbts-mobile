import 'package:flutter/material.dart';
import 'package:nbts/core/localization/app_language.dart';
import 'package:nbts/core/api/api_client.dart';
import 'package:nbts/core/api/service_locator.dart';
import 'package:nbts/core/data/models/donation_record.dart';
import 'package:nbts/core/data/models/user.dart';
import 'package:nbts/core/routes/app_routes.dart';
import 'package:nbts/core/theme/app_tokens.dart';
import 'package:nbts/core/widgets/app_card.dart';
import 'package:nbts/core/widgets/empty_state.dart';
import 'package:nbts/core/widgets/section_header.dart';
import 'package:nbts/core/widgets/stat_tile.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<User?> _profileFuture;
  late Future<List<DonationRecord>> _donationsFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _profileFuture = () async {
      try {
        return await Services.instance.profile.fetch();
      } catch (_) {
        return null;
      }
    }();
    _donationsFuture = Services.instance.donations.fetchAll();
  }

  Future<void> _refresh() async {
    setState(_load);
    await Future.wait([_profileFuture, _donationsFuture]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const SizedBox.shrink(),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () => _showHistoryFilterInfo(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: FutureBuilder<List<DonationRecord>>(
        future: _donationsFuture,
        builder: (context, donationsSnap) {
          if (donationsSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (donationsSnap.hasError) {
            final message = donationsSnap.error is ApiException
                ? (donationsSnap.error as ApiException).message
                : 'Could not load donation history.';
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  EmptyState(
                    icon: Icons.history_toggle_off_rounded,
                    title: 'History unavailable',
                    message: message,
                  ),
                ],
              ),
            );
          }

          final donations = donationsSnap.data ?? const <DonationRecord>[];
          return FutureBuilder<User?>(
            future: _profileFuture,
            builder: (context, profileSnap) {
              final user = profileSnap.data;
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
                    _ScreenHeader(
                      icon: Icons.history_rounded,
                      title: context.t('history.title'),
                      subtitle: context.t('history.subtitle'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SectionHeader(context.t('history.impact')),
                    Row(
                      children: [
                        Expanded(
                          child: AppCard(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: StatTile(
                              icon: Icons.water_drop_outlined,
                              value: _liters(user, donations),
                              unit: 'L',
                              label: context.t('history.totalDonated'),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AppCard(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: StatTile(
                              icon: Icons.favorite_outline_rounded,
                              value:
                                  '${user?.totalDonations ?? donations.length}',
                              label: context.t('dashboard.donations'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SectionHeader(context.t('dashboard.donations')),
                    if (donations.isEmpty)
                      AppCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: EmptyState(
                          icon: Icons.history_toggle_off_rounded,
                          title: context.t('history.noRecords'),
                          message: context.t('history.noRecordsMessage'),
                        ),
                      )
                    else
                      for (final d in donations)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _HistoryTile(record: d),
                        ),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.bookAppointment,
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(context.t('history.scheduleNext')),
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

  static String _liters(User? user, List<DonationRecord> records) {
    final ml =
        user?.totalVolumeMl ??
        records.fold<int>(0, (sum, record) => sum + (record.volumeMl ?? 0));
    return (ml / 1000).toStringAsFixed(1);
  }
}

class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            borderRadius: AppRadius.chip,
            border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
          ),
          child: Icon(icon, color: scheme.primary, size: 22),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.record});

  final DonationRecord record;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final date = record.date;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: AppRadius.chip,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  date == null ? '---' : _month(date),
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  date == null ? '--' : '${date.day}',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _text(record.centerName, fallback: 'NBTS center'),
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_text(record.status, fallback: 'Recorded')} - ${_formatDate(date)}',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${record.volumeMl ?? 0} mL',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _text(
                  record.donationType ?? record.bloodType,
                  fallback: 'blood',
                ).toUpperCase(),
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _month(DateTime date) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return months[date.month - 1];
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return 'Date pending';
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} $hh:$mm';
  }

  static String _text(String? value, {required String fallback}) {
    if (value == null || value.trim().isEmpty) return fallback;
    return value;
  }
}

void _showHistoryFilterInfo(BuildContext context) {
  showModalBottomSheet<void>(
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
            context.t('history.records'),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'This view shows all donation records currently synced from NBTS. Filters will become available when more record categories are provided by the backend.',
          ),
          const SizedBox(height: AppSpacing.lg),
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
}
