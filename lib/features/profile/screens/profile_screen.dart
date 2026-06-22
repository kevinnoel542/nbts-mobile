import 'package:flutter/material.dart';
import 'package:nbts/core/data/app_data.dart';
import 'package:nbts/core/routes/app_routes.dart';
import 'package:nbts/core/theme/app_tokens.dart';
import 'package:nbts/core/theme/theme_controller.dart';
import 'package:nbts/core/widgets/app_card.dart';
import 'package:nbts/core/widgets/section_header.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _push = true;
  bool _sms = true;
  bool _shareAnon = false;
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
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
          _Header(scheme: scheme),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader('Account'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _Row(
                  icon: Icons.qr_code_rounded,
                  label: 'Donor card',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.donorCard),
                ),
                _Divider(scheme: scheme),
                _Row(
                  icon: Icons.monitor_heart_outlined,
                  label: 'Medical summary',
                  onTap: () {},
                ),
                _Divider(scheme: scheme),
                _Row(
                  icon: Icons.contact_emergency_outlined,
                  label: 'Emergency contact',
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader('Notifications'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  value: _push,
                  onChanged: (v) => setState(() => _push = v),
                  title: const Text('Push notifications'),
                  subtitle: const Text('Appointments and urgent alerts'),
                ),
                _Divider(scheme: scheme),
                SwitchListTile.adaptive(
                  value: _sms,
                  onChanged: (v) => setState(() => _sms = v),
                  title: const Text('SMS reminders'),
                  subtitle: const Text('7, 3, 1 day reminders'),
                ),
                _Divider(scheme: scheme),
                SwitchListTile.adaptive(
                  value: _shareAnon,
                  onChanged: (v) => setState(() => _shareAnon = v),
                  title: const Text('Share anonymized data'),
                  subtitle:
                      const Text('Helps NBTS planning and donor safety'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader('Appearance'),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeController.mode,
            builder: (context, mode, _) => SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.brightness_auto_outlined),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (v) => ThemeController.set(v.first),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader('Language'),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'English', label: Text('English')),
              ButtonSegment(value: 'Swahili', label: Text('Swahili')),
            ],
            selected: {_language},
            onSelectionChanged: (v) => setState(() => _language = v.first),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader('Support'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _Row(
                  icon: Icons.help_outline_rounded,
                  label: 'FAQ and donor guide',
                  onTap: () {},
                ),
                _Divider(scheme: scheme),
                _Row(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Contact NBTS support',
                  onTap: () {},
                ),
                _Divider(scheme: scheme),
                _Row(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Account and privacy',
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.welcome,
              (_) => false,
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppData.donorName,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppData.donorId,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                        fontFamily: 'monospace',
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _Metric(
                label: 'Blood',
                value: AppData.bloodType,
                scheme: scheme,
              ),
              const SizedBox(width: AppSpacing.lg),
              _Metric(
                label: 'Donations',
                value: '${AppData.totalDonations}',
                scheme: scheme,
              ),
              const SizedBox(width: AppSpacing.lg),
              _Metric(
                label: 'Points',
                value: '${AppData.loyaltyPoints}',
                scheme: scheme,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
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

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: scheme.onSurfaceVariant),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, thickness: 1, color: scheme.outlineVariant);
  }
}
