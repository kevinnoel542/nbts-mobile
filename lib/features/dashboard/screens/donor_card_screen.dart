import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nbts/core/api/api_client.dart';
import 'package:nbts/core/api/service_locator.dart';
import 'package:nbts/core/data/models/donor_card.dart';
import 'package:nbts/core/theme/app_tokens.dart';
import 'package:nbts/core/widgets/app_card.dart';
import 'package:nbts/core/widgets/empty_state.dart';
import 'package:nbts/core/widgets/info_row.dart';
import 'package:nbts/core/widgets/status_pill.dart';
import 'package:qr_flutter/qr_flutter.dart';

class DonorCardScreen extends StatefulWidget {
  const DonorCardScreen({super.key});

  @override
  State<DonorCardScreen> createState() => _DonorCardScreenState();
}

class _DonorCardScreenState extends State<DonorCardScreen> {
  late Future<DonorCard> _cardFuture;

  @override
  void initState() {
    super.initState();
    _cardFuture = Services.instance.donorCard.fetch();
  }

  Future<void> _refresh() async {
    setState(() {
      _cardFuture = Services.instance.donorCard.fetch();
    });
    await _cardFuture;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Donor card'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () async {
              final card = await _cardFuture;
              if (!context.mounted) return;
              final text =
                  '''
NBTS Donor Card
Name: ${card.name ?? 'Pending'}
NBTS ID: ${card.donorId}
Blood group: ${card.bloodGroup ?? 'Pending'}
''';
              await Clipboard.setData(ClipboardData(text: text.trim()));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Donor card details copied.')),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: FutureBuilder<DonorCard>(
        future: _cardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : 'Could not load your donor card.';
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  EmptyState(
                    icon: Icons.badge_outlined,
                    title: 'Donor card unavailable',
                    message: message,
                  ),
                ],
              ),
            );
          }

          final card = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xxl + AppSpacing.lg,
              ),
              children: [
                _IdentityCard(scheme: scheme, card: card),
                const SizedBox(height: AppSpacing.lg),
                _QrPanel(scheme: scheme, card: card),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      InfoRow(
                        icon: Icons.event_available_outlined,
                        label: 'Next eligible',
                        value:
                            _formatDate(card.nextEligibleDate) ??
                            'Pending medical verification',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      InfoRow(
                        icon: Icons.place_outlined,
                        label: 'Home center',
                        value: _text(
                          card.preferredCenter,
                          fallback: 'No center selected',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      InfoRow(
                        icon: Icons.update_rounded,
                        label: 'QR expires',
                        value:
                            _formatDateTime(card.qrExpiresAt) ??
                            'Refresh daily',
                      ),
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

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.scheme, required this.card});

  final ColorScheme scheme;
  final DonorCard card;

  @override
  Widget build(BuildContext context) {
    final verified = card.bloodGroupVerified == true;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.water_drop_rounded, size: 18, color: scheme.primary),
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
              StatusPill(
                label: verified ? 'Verified' : 'Unverified',
                icon: verified
                    ? Icons.verified_outlined
                    : Icons.pending_outlined,
                kind: verified ? StatusKind.success : StatusKind.warning,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            _text(card.name, fallback: 'Donor profile pending'),
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            card.donorId,
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
                value: _text(card.bloodGroup, fallback: 'Pending'),
                scheme: scheme,
              ),
              const SizedBox(width: AppSpacing.lg),
              _MiniField(
                label: 'Donations',
                value: '${card.totalDonations ?? 0}',
                scheme: scheme,
              ),
              const SizedBox(width: AppSpacing.lg),
              _MiniField(
                label: 'Tier',
                value: _text(card.loyaltyTier, fallback: 'Pending'),
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
  const _QrPanel({required this.scheme, required this.card});

  final ColorScheme scheme;
  final DonorCard card;

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
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.card,
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: QrImageView(
              data: card.qrPayloadText,
              version: QrVersions.auto,
              size: 180,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
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

String? _formatDate(DateTime? date) {
  if (date == null) return null;
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
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String? _formatDateTime(DateTime? date) {
  if (date == null) return null;
  final hh = date.hour.toString().padLeft(2, '0');
  final mm = date.minute.toString().padLeft(2, '0');
  return '${_formatDate(date)}  $hh:$mm';
}
