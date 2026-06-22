import 'package:flutter/material.dart';
import 'package:nbts/core/data/app_data.dart';
import 'package:nbts/core/theme/app_tokens.dart';
import 'package:nbts/core/widgets/app_card.dart';
import 'package:nbts/core/widgets/info_row.dart';
import 'package:nbts/core/widgets/status_pill.dart';

class DonorCardScreen extends StatelessWidget {
  const DonorCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Donor card'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          _IdentityCard(scheme: scheme),
          const SizedBox(height: AppSpacing.lg),
          _QrPanel(scheme: scheme),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: const [
                InfoRow(
                  icon: Icons.event_available_outlined,
                  label: 'Next eligible',
                  value: AppData.nextEligibleDate,
                ),
                SizedBox(height: AppSpacing.md),
                InfoRow(
                  icon: Icons.place_outlined,
                  label: 'Home center',
                  value: AppData.preferredCenter,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.water_drop_rounded,
                size: 18,
                color: scheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'NBTS donor',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              const StatusPill(
                label: 'Verified',
                icon: Icons.verified_outlined,
                kind: StatusKind.success,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            AppData.donorName,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppData.donorId,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 13,
              fontFamily: 'monospace',
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _MiniField(
                label: 'Blood',
                value: AppData.bloodType,
                scheme: scheme,
              ),
              const SizedBox(width: AppSpacing.lg),
              _MiniField(
                label: 'Donations',
                value: '${AppData.totalDonations}',
                scheme: scheme,
              ),
              const SizedBox(width: AppSpacing.lg),
              _MiniField(
                label: 'Tier',
                value: AppData.loyaltyTier,
                scheme: scheme,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniField extends StatelessWidget {
  const _MiniField({
    required this.label,
    required this.value,
    required this.scheme,
  });

  final String label;
  final String value;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _QrPanel extends StatelessWidget {
  const _QrPanel({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Text(
            'Express check-in',
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Show this code at any NBTS center.',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: AppRadius.card,
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Icon(
              Icons.qr_code_2_rounded,
              size: 180,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Refreshes every 24 hours',
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
