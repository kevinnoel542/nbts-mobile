import 'package:flutter/material.dart';
import 'package:nbts/core/localization/app_language.dart';
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
        title: Text(context.t('centers.title')),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                hintText: context.t('centers.search'),
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
                      title: context.t('centers.unavailable'),
                      message: message,
                    ),
                  );
                }

                final centers = snapshot.data ?? const <DonationCenter>[];
                final filtered = _filter(centers);
                if (filtered.isEmpty) {
                  return _StateList(
                    onRefresh: _refresh,
                    child: EmptyState(
                      icon: Icons.place_outlined,
                      title: context.t('centers.none'),
                      message: context.t('centers.noneMessage'),
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
                      AppSpacing.xxl + AppSpacing.lg,
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
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              (c.address ?? '').toLowerCase().contains(q) ||
              (c.phone ?? '').toLowerCase().contains(q) ||
              c.services.any((service) => service.toLowerCase().contains(q)),
        )
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
          AppSpacing.xxl + AppSpacing.lg,
        ),
        children: [child],
      ),
    );
  }
}

class _CenterTile extends StatelessWidget {
  const _CenterTile({required this.center});

  final DonationCenter center;

  void _bookHere(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.bookAppointment, arguments: center);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isClosed = center.isOpen == false;
    final services = center.services.take(3).toList();
    final capacity = center.waitTime ?? center.capacityLabel;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      center.name,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _Detail(
                      icon: Icons.place_outlined,
                      label:
                          center.address ?? context.t('centers.addressPending'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusPill(
                label: isClosed
                    ? context.t('centers.closed')
                    : context.t('centers.open'),
                kind: isClosed ? StatusKind.neutral : StatusKind.success,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              _Detail(
                icon: Icons.schedule_outlined,
                label: center.hours ?? context.t('centers.hoursPending'),
              ),
              _Detail(
                icon: Icons.phone_outlined,
                label: center.phone ?? context.t('centers.phonePending'),
              ),
              if (center.distanceKm != null)
                _Detail(
                  icon: Icons.near_me_outlined,
                  label: '${center.distanceKm!.toStringAsFixed(1)} km',
                ),
              if (capacity != null && capacity.trim().isNotEmpty)
                _Detail(icon: Icons.timelapse_outlined, label: capacity),
            ],
          ),
          if (services.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final service in services)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: AppRadius.pill,
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Text(
                      service,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isClosed ? null : () => _bookHere(context),
                  icon: const Icon(Icons.calendar_month_outlined, size: 18),
                  label: Text(context.t('centers.bookHere')),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 210),
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
    );
  }
}

