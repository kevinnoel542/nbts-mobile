import 'package:flutter/material.dart';
import 'package:nbts/core/api/api_client.dart';
import 'package:nbts/core/api/service_locator.dart';
import 'package:nbts/core/data/models/donation_center.dart';
import 'package:nbts/core/routes/app_routes.dart';
import 'package:nbts/core/theme/app_tokens.dart';
import 'package:nbts/core/widgets/app_card.dart';
import 'package:nbts/core/widgets/empty_state.dart';
import 'package:nbts/core/widgets/status_pill.dart';

class FindCentersScreen extends StatefulWidget {
  const FindCentersScreen({super.key});

  @override
  State<FindCentersScreen> createState() => _FindCentersScreenState();
}

class _FindCentersScreenState extends State<FindCentersScreen> {
  String _query = '';
  late Future<List<DonationCenter>> _centersFuture;

  @override
  void initState() {
    super.initState();
    _centersFuture = Services.instance.centers.fetchAll();
  }

  Future<void> _refresh() async {
    setState(() {
      _centersFuture = Services.instance.centers.fetchAll();
    });
    await _centersFuture;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Centers'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search by name or area',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: scheme.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.pill,
                  borderSide: BorderSide(color: scheme.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.pill,
                  borderSide: BorderSide(color: scheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.pill,
                  borderSide: BorderSide(color: scheme.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<DonationCenter>>(
              future: _centersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  final message = snapshot.error is ApiException
                      ? (snapshot.error as ApiException).message
                      : 'Could not load donation centers.';
                  return _StateList(
                    onRefresh: _refresh,
                    child: EmptyState(
                      icon: Icons.cloud_off_outlined,
                      title: 'Centers unavailable',
                      message: message,
                    ),
                  );
                }

                final centers = snapshot.data ?? const <DonationCenter>[];
                final filtered = _filter(centers);
                if (filtered.isEmpty) {
                  return _StateList(
                    onRefresh: _refresh,
                    child: const EmptyState(
                      icon: Icons.place_outlined,
                      title: 'No centers found',
                      message:
                          'Try another area or pull to refresh NBTS centers.',
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (_, i) => _CenterTile(center: filtered[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<DonationCenter> _filter(List<DonationCenter> centers) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return centers;
    return centers
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            (c.address ?? '').toLowerCase().contains(q))
        .toList();
  }
}

class _StateList extends StatelessWidget {
  const _StateList({required this.child, required this.onRefresh});

  final Widget child;
  final RefreshCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [child],
      ),
    );
  }
}

class _CenterTile extends StatelessWidget {
  const _CenterTile({required this.center});

  final DonationCenter center;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isClosed = center.isOpen == false;

    return AppCard(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.bookAppointment,
        arguments: center,
      ),
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
                label: isClosed ? 'Closed' : 'Open',
                kind: isClosed ? StatusKind.neutral : StatusKind.success,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            center.address ?? 'Address pending',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _Detail(
                icon: Icons.near_me_outlined,
                label: center.distanceKm == null
                    ? 'Distance pending'
                    : '${center.distanceKm!.toStringAsFixed(1)} km',
              ),
              const SizedBox(width: AppSpacing.md),
              _Detail(
                icon: Icons.schedule_outlined,
                label: center.hours ?? 'Hours pending',
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  center.waitTime ?? center.capacityLabel ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
