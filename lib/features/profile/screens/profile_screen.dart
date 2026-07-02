import 'package:flutter/material.dart';
import 'package:nbts/core/api/api_client.dart';
import 'package:nbts/core/api/service_locator.dart';
import 'package:nbts/core/data/models/user.dart';
import 'package:nbts/core/routes/app_routes.dart';
import 'package:nbts/core/theme/app_tokens.dart';
import 'package:nbts/core/theme/theme_controller.dart';
import 'package:nbts/core/widgets/app_card.dart';
import 'package:nbts/core/widgets/empty_state.dart';
import 'package:nbts/core/widgets/section_header.dart';
import 'package:nbts/features/auth/services/firebase_social_auth_service.dart';

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
  bool _prefsHydrated = false;
  late Future<User> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = Services.instance.profile.fetch();
  }

  Future<void> _refresh() async {
    setState(() {
      _profileFuture = Services.instance.profile.fetch();
    });
    await _profileFuture;
  }

  Future<void> _signOut() async {
    await Services.instance.auth.logout();
    try {
      await FirebaseSocialAuthService.signOut();
    } catch (_) {
      // Local Laravel sign-out should still complete even if Firebase is unavailable.
    }
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.welcome, (_) => false);
  }

  Future<void> _updatePreference(String key, bool value) async {
    try {
      await Services.instance.profile.update({key: value});
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Preference updated.')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.firstError())));
    }
  }

  Future<void> _updateLanguage(String language) async {
    final previous = _language;
    setState(() => _language = language);
    try {
      await Services.instance.profile.update({
        'language': language == 'Swahili' ? 'sw' : 'en',
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Language updated.')));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _language = previous);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.firstError())));
    }
  }

  void _showInfoSheet({
    required String title,
    required IconData icon,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
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
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(message),
            const SizedBox(height: AppSpacing.lg),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: onAction ?? () => Navigator.pop(context),
                child: Text(actionLabel ?? 'Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
            onPressed: () => _showInfoSheet(
              title: 'Edit profile',
              icon: Icons.edit_outlined,
              message:
                  'Use the account rows below to review your donor card, medical summary, emergency contact, and preferences.',
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: FutureBuilder<User>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : 'Could not load your profile.';
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  EmptyState(
                    icon: Icons.person_off_outlined,
                    title: 'Profile unavailable',
                    message: message,
                  ),
                ],
              ),
            );
          }

          final user = snapshot.data;
          if (!_prefsHydrated && user != null) {
            _push = user.pushNotificationsEnabled ?? _push;
            _sms = user.smsRemindersEnabled ?? _sms;
            _shareAnon = user.shareAnonymizedData ?? _shareAnon;
            _language = _languageLabel(user.language) ?? _language;
            _prefsHydrated = true;
          }
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
                _Header(scheme: scheme, user: user),
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
                        onTap: () => _showInfoSheet(
                          title: 'Medical summary',
                          icon: Icons.monitor_heart_outlined,
                          message:
                              'Your blood group, eligibility, donation count, and next eligible date are shown across the home, donor card, and history screens.',
                          actionLabel: 'View donor card',
                          onAction: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, AppRoutes.donorCard);
                          },
                        ),
                      ),
                      _Divider(scheme: scheme),
                      _Row(
                        icon: Icons.contact_emergency_outlined,
                        label: 'Emergency contact',
                        onTap: () => _showInfoSheet(
                          title: 'Emergency contact',
                          icon: Icons.contact_emergency_outlined,
                          message:
                              'Emergency contact editing is stored on the backend profile endpoint. Ask staff to verify this information before donation day.',
                        ),
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
                        onChanged: (v) {
                          setState(() => _push = v);
                          _updatePreference('push_notifications_enabled', v);
                        },
                        title: const Text('Push notifications'),
                        subtitle: const Text('Appointments and urgent alerts'),
                      ),
                      _Divider(scheme: scheme),
                      SwitchListTile.adaptive(
                        value: _sms,
                        onChanged: (v) {
                          setState(() => _sms = v);
                          _updatePreference('sms_reminders_enabled', v);
                        },
                        title: const Text('SMS reminders'),
                        subtitle: const Text('7, 3, 1 day reminders'),
                      ),
                      _Divider(scheme: scheme),
                      SwitchListTile.adaptive(
                        value: _shareAnon,
                        onChanged: (v) {
                          setState(() => _shareAnon = v);
                          _updatePreference('share_anonymized_data', v);
                        },
                        title: const Text('Share anonymized data'),
                        subtitle: const Text(
                          'Helps NBTS planning and donor safety',
                        ),
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
                  onSelectionChanged: (v) => _updateLanguage(v.first),
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
                        onTap: () => _showInfoSheet(
                          title: 'FAQ and donor guide',
                          icon: Icons.help_outline_rounded,
                          message:
                              'Bring a valid ID, eat before donating, drink water, and tell NBTS staff about medication or recent illness before donation.',
                        ),
                      ),
                      _Divider(scheme: scheme),
                      _Row(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Contact NBTS support',
                        onTap: () => _showInfoSheet(
                          title: 'Contact NBTS support',
                          icon: Icons.chat_bubble_outline_rounded,
                          message:
                              'For urgent appointment or donor record support, contact your nearest NBTS center or use the center list in the app.',
                          actionLabel: 'Find centers',
                          onAction: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, AppRoutes.centers);
                          },
                        ),
                      ),
                      _Divider(scheme: scheme),
                      _Row(
                        icon: Icons.privacy_tip_outlined,
                        label: 'Account and privacy',
                        onTap: () => _showInfoSheet(
                          title: 'Account and privacy',
                          icon: Icons.privacy_tip_outlined,
                          message:
                              'Your donor profile is used for eligibility, appointment reminders, donation history, and NBTS planning. You can sign out from this screen any time.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                OutlinedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign out'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.scheme, required this.user});

  final ColorScheme scheme;
  final User? user;

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
                      _text(user?.name, fallback: 'Donor profile pending'),
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'NBTS ID',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _text(user?.donorId, fallback: 'Pending'),
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
                value: _text(user?.bloodGroup, fallback: 'Pending'),
                scheme: scheme,
              ),
              const SizedBox(width: AppSpacing.lg),
              _Metric(
                label: 'Donations',
                value: '${user?.totalDonations ?? 0}',
                scheme: scheme,
              ),
              const SizedBox(width: AppSpacing.lg),
              _Metric(
                label: 'Donor points',
                value: '${user?.loyaltyPoints ?? 0}',
                scheme: scheme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _text(String? value, {required String fallback}) {
    if (value == null || value.trim().isEmpty) return fallback;
    return value;
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
  const _Row({required this.icon, required this.label, required this.onTap});

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

String? _languageLabel(String? value) {
  final normalized = value?.toLowerCase().trim();
  return switch (normalized) {
    'sw' || 'swahili' || 'kiswahili' => 'Swahili',
    'en' || 'english' => 'English',
    _ => null,
  };
}
