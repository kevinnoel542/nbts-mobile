import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nbts/core/localization/app_language.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
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
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _push = true;
  bool _sms = true;
  String _language = LanguageController.label(LanguageController.code.value);
  bool _prefsHydrated = false;
  bool _photoUploading = false;
  User? _lastUser;
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
    await LanguageController.set(language);
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
      await LanguageController.set(previous);
      if (!mounted) return;
      setState(() => _language = previous);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.firstError())));
    }
  }

  String _text(String? value, {required String fallback}) {
    if (value == null || value.trim().isEmpty) return fallback;
    return value;
  }

  String _copy(String key) {
    final sw = _language == 'Swahili';
    if (!sw) {
      return switch (key) {
        'profileTitle' => 'Profile',
        'account' => 'Account',
        'donorCard' => 'Donor card',
        'medicalSummary' => 'Medical summary',
        'emergencyContact' => 'Emergency contact',
        'notifications' => 'Notifications',
        'pushNotifications' => 'Push notifications',
        'smsReminders' => 'SMS reminders',
        'appearance' => 'Appearance',
        'light' => 'Light',
        'dark' => 'Dark',
        'system' => 'System',
        'language' => 'Language',
        'support' => 'Support',
        'faq' => 'FAQ and donor guide',
        'contactSupport' => 'Contact NBTS support',
        'privacy' => 'Account and privacy',
        'signOut' => 'Sign out',
        _ => key,
      };
    }

    return switch (key) {
      'profileTitle' => 'Wasifu',
      'account' => 'Akaunti',
      'donorCard' => 'Kadi ya mchangiaji',
      'medicalSummary' => 'Muhtasari wa afya',
      'emergencyContact' => 'Mawasiliano ya dharura',
      'notifications' => 'Arifa',
      'pushNotifications' => 'Arifa za programu',
      'smsReminders' => 'Vikumbusho vya SMS',
      'appearance' => 'Mwonekano',
      'light' => 'Mwanga',
      'dark' => 'Giza',
      'system' => 'Mfumo',
      'language' => 'Lugha',
      'support' => 'Msaada',
      'faq' => 'Maswali na mwongozo',
      'contactSupport' => 'Wasiliana na NBTS',
      'privacy' => 'Akaunti na faragha',
      'signOut' => 'Toka',
      _ => key,
    };
  }

  Future<void> _pickProfilePhoto() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() => _photoUploading = true);
      final user = await Services.instance.profile.updatePhoto(
        File(picked.path),
      );
      _lastUser = user;
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('profile.photoUpdated'))),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.firstError())));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not update photo: $e')));
    } finally {
      if (mounted) setState(() => _photoUploading = false);
    }
  }

  void _showMedicalSummary(User? user) {
    final scheme = Theme.of(context).colorScheme;
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
            Row(
              children: [
                Icon(Icons.monitor_heart_outlined, color: scheme.primary),
                const SizedBox(width: 10),
                Text(
                  _copy('medicalSummary'),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _SummaryLine(
              label: context.t('auth.bloodGroup'),
              value: _text(
                user?.bloodGroup,
                fallback: context.t('common.pending'),
              ),
            ),
            _SummaryLine(
              label: context.t('auth.gender'),
              value: _text(user?.gender, fallback: context.t('common.pending')),
            ),
            _SummaryLine(
              label: context.t('auth.region'),
              value: _text(user?.region, fallback: context.t('common.pending')),
            ),
            _SummaryLine(
              label: context.t('auth.dateOfBirth'),
              value:
                  _formatDate(user?.dateOfBirth) ?? context.t('common.pending'),
            ),
            _SummaryLine(
              label: context.t('dashboard.nextEligible'),
              value:
                  _formatDate(user?.nextEligibleDate) ??
                  context.t('common.pendingMedical'),
            ),
            _SummaryLine(
              label: context.t('medical.totalDonations'),
              value: '${user?.totalDonations ?? 0}',
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.donorCard);
                },
                icon: const Icon(Icons.qr_code_rounded),
                label: Text(context.t('medical.openCard')),
              ),
            ),
          ],
        ),
      ),
    );
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
        title: Text(_copy('profileTitle')),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final changed = await Navigator.pushNamed(
                context,
                AppRoutes.completeProfile,
                arguments: {'mode': 'edit', 'user': _lastUser},
              );
              if (changed == true && mounted) await _refresh();
            },
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
          _lastUser = user;
          if (!_prefsHydrated && user != null) {
            _push = user.pushNotificationsEnabled ?? _push;
            _sms = user.smsRemindersEnabled ?? _sms;
            _language =
                _languageLabel(user.language) ??
                LanguageController.label(LanguageController.code.value);
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
                _Header(
                  scheme: scheme,
                  user: user,
                  uploadingPhoto: _photoUploading,
                  onPhotoTap: _photoUploading ? null : _pickProfilePhoto,
                ),
                const SizedBox(height: AppSpacing.xl),
                SectionHeader(_copy('account')),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _Row(
                        icon: Icons.qr_code_rounded,
                        label: _copy('donorCard'),
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.donorCard),
                      ),
                      _Divider(scheme: scheme),
                      _Row(
                        icon: Icons.monitor_heart_outlined,
                        label: _copy('medicalSummary'),
                        onTap: () => _showMedicalSummary(user),
                      ),
                      _Divider(scheme: scheme),
                      _Row(
                        icon: Icons.contact_emergency_outlined,
                        label: _copy('emergencyContact'),
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
                SectionHeader(_copy('notifications')),
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
                        title: Text(_copy('pushNotifications')),
                      ),
                      _Divider(scheme: scheme),
                      SwitchListTile.adaptive(
                        value: _sms,
                        onChanged: (v) {
                          setState(() => _sms = v);
                          _updatePreference('sms_reminders_enabled', v);
                        },
                        title: Text(_copy('smsReminders')),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SectionHeader(_copy('appearance')),
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: ThemeController.mode,
                  builder: (context, mode, _) => SegmentedButton<ThemeMode>(
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text(_copy('light')),
                        icon: const Icon(Icons.light_mode_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text(_copy('dark')),
                        icon: const Icon(Icons.dark_mode_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text(_copy('system')),
                        icon: const Icon(Icons.brightness_auto_outlined),
                      ),
                    ],
                    selected: {mode},
                    onSelectionChanged: (v) => ThemeController.set(v.first),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SectionHeader(_copy('language')),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'English', label: Text('English')),
                    ButtonSegment(value: 'Swahili', label: Text('Swahili')),
                  ],
                  selected: {_language},
                  onSelectionChanged: (v) => _updateLanguage(v.first),
                ),
                const SizedBox(height: AppSpacing.xl),
                SectionHeader(_copy('support')),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _Row(
                        icon: Icons.help_outline_rounded,
                        label: _copy('faq'),
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
                        label: _copy('contactSupport'),
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
                        label: _copy('privacy'),
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
                  label: Text(_copy('signOut')),
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
  const _Header({
    required this.scheme,
    required this.user,
    required this.uploadingPhoto,
    required this.onPhotoTap,
  });

  final ColorScheme scheme;
  final User? user;
  final bool uploadingPhoto;
  final VoidCallback? onPhotoTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ProfileAvatar(
                scheme: scheme,
                photoUrl:
                    user?.photoUrl ??
                    firebase_auth.FirebaseAuth.instance.currentUser?.photoURL,
                uploading: uploadingPhoto,
                onTap: onPhotoTap,
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
                      context.t('profile.nbtsId'),
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _text(
                        user?.donorId,
                        fallback: context.t('common.pending'),
                      ),
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
                label: context.t('profile.blood'),
                value: _text(
                  user?.bloodGroup,
                  fallback: context.t('common.pending'),
                ),
                scheme: scheme,
              ),
              const SizedBox(width: AppSpacing.lg),
              _Metric(
                label: context.t('dashboard.donations'),
                value: '${user?.totalDonations ?? 0}',
                scheme: scheme,
              ),
              const SizedBox(width: AppSpacing.lg),
              _Metric(
                label: context.t('profile.donorPoints'),
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

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.scheme,
    required this.photoUrl,
    required this.uploading,
    required this.onTap,
  });

  final ColorScheme scheme;
  final String? photoUrl;
  final bool uploading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.trim().isNotEmpty;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: scheme.surfaceContainerHigh,
            backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
            child: uploading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: scheme.primary,
                    ),
                  )
                : hasPhoto
                ? null
                : Icon(
                    Icons.person_outline_rounded,
                    color: scheme.onSurfaceVariant,
                    size: 30,
                  ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.surface, width: 2),
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                size: 13,
                color: scheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
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

String? _languageLabel(String? value) {
  final normalized = value?.toLowerCase().trim();
  return switch (normalized) {
    'sw' || 'swahili' || 'kiswahili' => 'Swahili',
    'en' || 'english' => 'English',
    _ => null,
  };
}


