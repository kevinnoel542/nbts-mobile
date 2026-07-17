import 'package:flutter/material.dart';
import 'package:nbts/core/localization/app_language.dart';
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
        title: Text(context.t('donorCard.title')),
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
                SnackBar(content: Text(context.t('donorCard.copied'))),
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
                        label: context.t('dashboard.nextEligible'),
                        value:
                            _formatDate(card.nextEligibleDate) ??
                            context.t('common.pendingMedical'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      InfoRow(
                        icon: Icons.place_outlined,
                        label: context.t('donorCard.homeCenter'),
                        value: _text(
                          card.preferredCenter,
                          fallback: context.t('common.pending'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      InfoRow(
                        icon: Icons.update_rounded,
                        label: context.t('donorCard.qrExpires'),
                        value:
                            _formatDateTime(card.qrExpiresAt) ??
                            context.t('common.refresh'),
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
    final isDark = scheme.brightness == Brightness.dark;
    final bg = _text(card.bloodGroup, fallback: '--');

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF201315), const Color(0xFF101010)]
              : [const Color(0xFFFFF7F7), Colors.white],
        ),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: isDark ? 0.18 : 0.10),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.26),
                      width: 3,
                    ),
                  ),
                  child: Text(
                    bg,
                    style: TextStyle(
                      color: scheme.onPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.water_drop_rounded,
                            size: 16,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            context.t('donorCard.digital'),
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _text(
                          card.name,
                          fallback: context.t('dashboard.welcomeDonor'),
                        ),
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        context.t('profile.nbtsId'),
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.9,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        card.donorId,
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 13,
                          fontFamily: 'monospace',
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            StatusPill(
              label: verified
                  ? context.t('donorCard.bloodVerified')
                  : context.t('common.pendingMedical'),
              icon: verified ? Icons.verified_outlined : Icons.pending_outlined,
              kind: verified ? StatusKind.success : StatusKind.warning,
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: isDark ? 0.32 : 0.70),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _MiniField(
                      label: context.t('dashboard.donations'),
                      value: '${card.totalDonations ?? 0}',
                      scheme: scheme,
                    ),
                  ),
                  Expanded(
                    child: _MiniField(
                      label: context.t('profile.donorPoints'),
                      value: '${card.loyaltyPoints ?? 0}',
                      scheme: scheme,
                    ),
                  ),
                  Expanded(
                    child: _MiniField(
                      label: 'Tier',
                      value: _text(
                        card.loyaltyTier,
                        fallback: context.t('common.pending'),
                      ),
                      scheme: scheme,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
            context.t('donorCard.qrTitle'),
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.t('donorCard.qrSubtitle'),
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
              size: 220,
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
