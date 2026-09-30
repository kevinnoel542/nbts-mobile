import 'package:flutter/material.dart';
import 'package:nbts/core/api/api_client.dart';
import 'package:nbts/core/api/service_locator.dart';
import 'package:nbts/core/data/models/article.dart';
import 'package:nbts/core/data/models/campaign.dart';
import 'package:nbts/core/data/models/donation_center.dart';
import 'package:nbts/core/localization/app_language.dart';
import 'package:nbts/core/routes/app_routes.dart';
import 'package:nbts/core/theme/app_tokens.dart';
import 'package:nbts/core/widgets/app_card.dart';
import 'package:nbts/core/widgets/empty_state.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  late Future<_DiscoverData> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = () async {
      final results = await Future.wait<dynamic>([
        Services.instance.campaigns.fetchAll(),
        Services.instance.articles.fetchAll(),
        Services.instance.articles.fetchPublications(),
        Services.instance.campaigns.fetchSchedules(),
      ]);
      return _DiscoverData(
        campaigns: results[0] as List<Campaign>,
        articles: results[1] as List<Article>,
        publications: results[2] as List<Article>,
        schedules: results[3] as List<Campaign>,
      );
    }();
  }

  Future<void> _refresh() async {
    setState(_load);
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.t('discover.title')),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: context.t('discover.campaigns')),
              Tab(text: context.t('discover.articles')),
              Tab(text: context.t('discover.publications')),
              Tab(text: context.t('discover.schedules')),
            ],
          ),
        ),
        body: FutureBuilder<_DiscoverData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              final message = snapshot.error is ApiException
                  ? (snapshot.error as ApiException).safeMessage
                  : context.t('discover.loadFailed');
              return _ErrorBody(message: message, onRefresh: _refresh);
            }
            final data = snapshot.data!;
            return TabBarView(
              children: [
                _CampaignList(items: data.campaigns, onRefresh: _refresh),
                _ArticleList(items: data.articles, onRefresh: _refresh),
                _ArticleList(items: data.publications, onRefresh: _refresh),
                _CampaignList(
                  items: data.schedules,
                  onRefresh: _refresh,
                  schedules: true,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DiscoverData {
  const _DiscoverData({
    required this.campaigns,
    required this.articles,
    required this.publications,
    required this.schedules,
  });
  final List<Campaign> campaigns;
  final List<Article> articles;
  final List<Article> publications;
  final List<Campaign> schedules;
}

class _CampaignList extends StatelessWidget {
  const _CampaignList({
    required this.items,
    required this.onRefresh,
    this.schedules = false,
  });
  final List<Campaign> items;
  final RefreshCallback onRefresh;
  final bool schedules;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyList(
        onRefresh: onRefresh,
        message: context.t('discover.none'),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final item = items[index];
          return AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            onTap: () => _showCampaign(context, item, schedules: schedules),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  item.urgent == true
                      ? Icons.campaign_rounded
                      : Icons.event_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      if (item.summary?.isNotEmpty == true) ...[
                        const SizedBox(height: 5),
                        Text(
                          item.summary!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        _dateRange(item.startsAt, item.endsAt),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ArticleList extends StatelessWidget {
  const _ArticleList({required this.items, required this.onRefresh});
  final List<Article> items;
  final RefreshCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyList(
        onRefresh: onRefresh,
        message: context.t('discover.none'),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final item = items[index];
          return AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            onTap: () => _showArticle(context, item),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.article_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.summary ??
                            item.body ??
                            context.t('discover.noDetails'),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList({required this.onRefresh, required this.message});
  final RefreshCallback onRefresh;
  final String message;
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          EmptyState(
            icon: Icons.inbox_outlined,
            title: context.t('discover.empty'),
            message: message,
          ),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRefresh});
  final String message;
  final RefreshCallback onRefresh;
  @override
  Widget build(BuildContext context) =>
      _EmptyList(onRefresh: onRefresh, message: message);
}

void _showCampaign(
  BuildContext context,
  Campaign campaign, {
  required bool schedules,
}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              campaign.title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(campaign.summary ?? context.t('discover.noDetails')),
            const SizedBox(height: AppSpacing.md),
            Text(_dateRange(campaign.startsAt, campaign.endsAt)),
            if (campaign.centerName != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(campaign.centerName!),
            ],
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  if (campaign.centerId != null) {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.bookAppointment,
                      arguments: DonationCenter(
                        id: campaign.centerId!,
                        name: campaign.centerName ?? campaign.title,
                      ),
                    );
                  } else {
                    Navigator.pushNamed(context, AppRoutes.centers);
                  }
                },
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(context.t('discover.bookDonation')),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showArticle(BuildContext context, Article article) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      maxChildSize: 0.92,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          Text(
            article.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            article.body ?? article.summary ?? context.t('discover.noDetails'),
            style: const TextStyle(height: 1.55),
          ),
        ],
      ),
    ),
  );
}

String _dateRange(DateTime? start, DateTime? end) {
  if (start == null) return '';
  String format(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  if (end == null) return format(start);
  return '${format(start)} - ${format(end)}';
}
