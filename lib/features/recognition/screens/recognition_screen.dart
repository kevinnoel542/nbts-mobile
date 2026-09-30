import 'package:flutter/material.dart';
import 'package:nbts/core/api/api_client.dart';
import 'package:nbts/core/api/service_locator.dart';
import 'package:nbts/core/data/models/loyalty.dart';
import 'package:nbts/core/localization/app_language.dart';
import 'package:nbts/core/theme/app_tokens.dart';
import 'package:nbts/core/widgets/app_card.dart';
import 'package:nbts/core/widgets/empty_state.dart';
import 'package:nbts/core/widgets/section_header.dart';

class RecognitionScreen extends StatefulWidget {
  const RecognitionScreen({super.key});

  @override
  State<RecognitionScreen> createState() => _RecognitionScreenState();
}

class _RecognitionScreenState extends State<RecognitionScreen> {
  late Future<(LoyaltySummary, List<LeaderboardEntry>)> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = () async {
      final results = await Future.wait<dynamic>([
        Services.instance.loyalty.fetchSummary(),
        Services.instance.loyalty.fetchLeaderboard(),
      ]);
      return (
        results[0] as LoyaltySummary,
        results[1] as List<LeaderboardEntry>,
      );
    }();
  }

  Future<void> _refresh() async {
    setState(_load);
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t('recognition.title'))),
      body: FutureBuilder<(LoyaltySummary, List<LeaderboardEntry>)>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).safeMessage
                : context.t('recognition.loadFailed');
            return _RefreshBody(
              onRefresh: _refresh,
              child: EmptyState(
                icon: Icons.workspace_premium_outlined,
                title: context.t('recognition.unavailable'),
                message: message,
              ),
            );
          }

          final (summary, leaderboard) = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              children: [
                _SummaryCard(summary: summary),
                const SizedBox(height: AppSpacing.xl),
                SectionHeader(context.t('recognition.badges')),
                if (summary.badges.isEmpty)
                  _EmptyCard(message: context.t('recognition.noBadges'))
                else
                  for (final badge in summary.badges)
                    _AwardTile(
                      award: badge,
                      icon: Icons.military_tech_outlined,
                    ),
                const SizedBox(height: AppSpacing.xl),
                SectionHeader(context.t('recognition.rewards')),
                if (summary.rewards.isEmpty)
                  _EmptyCard(message: context.t('recognition.noRewards'))
                else
                  for (final reward in summary.rewards)
                    _AwardTile(
                      award: reward,
                      icon: Icons.card_giftcard_outlined,
                    ),
                const SizedBox(height: AppSpacing.xl),
                SectionHeader(context.t('recognition.leaderboard')),
                if (leaderboard.isEmpty)
                  _EmptyCard(message: context.t('recognition.noLeaderboard'))
                else
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < leaderboard.length; i++) ...[
                          _LeaderboardTile(entry: leaderboard[i]),
                          if (i != leaderboard.length - 1)
                            Divider(
                              height: 1,
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),
                        ],
                      ],
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});
  final LoyaltySummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary.tier,
            style: TextStyle(
              color: scheme.onPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _Metric(
                label: context.t('recognition.points'),
                value: '${summary.points}',
              ),
              _Metric(
                label: context.t('recognition.donations'),
                value: '${summary.totalDonations}',
              ),
              _Metric(
                label: context.t('recognition.rank'),
                value: summary.rank == null ? '-' : '#${summary.rank}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onPrimary;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            style: TextStyle(
              color: color.withValues(alpha: 0.82),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _AwardTile extends StatelessWidget {
  const _AwardTile({required this.award, required this.icon});
  final LoyaltyAward award;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
          title: Text(
            award.name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: award.description == null ? null : Text(award.description!),
          trailing: award.status == null ? null : Text(award.status!),
        ),
      ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({required this.entry});
  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: entry.isCurrentUser
          ? scheme.primary.withValues(alpha: 0.08)
          : Colors.transparent,
      child: ListTile(
        leading: CircleAvatar(child: Text('${entry.rank}')),
        title: Text(
          entry.displayName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(entry.tier),
        trailing: Text(
          '${entry.donationCount}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _RefreshBody extends StatelessWidget {
  const _RefreshBody({required this.onRefresh, required this.child});
  final RefreshCallback onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [child],
      ),
    );
  }
}
