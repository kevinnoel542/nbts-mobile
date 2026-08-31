import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:nbts/core/api/api_config.dart';
import 'package:nbts/core/api/api_client.dart';
import 'package:nbts/core/api/service_locator.dart';
import 'package:nbts/core/data/models/user.dart';
import 'package:nbts/core/localization/app_language.dart';
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
    await Services.instance.notificationService.unregisterDeviceToken();
    await Services.instance.auth.logout();
    try {
      await FirebaseSocialAuthService.signOut();
    } catch (_) {
      // Local Laravel sign-out should still complete even if Firebase is unavailable.
    }
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.welcome, (_) => false);
  }

  bool _hasSmsPhone() => (_lastUser?.phone ?? '').trim().isNotEmpty;

  Future<void> _editProfile() async {
    final changed = await Navigator.pushNamed(
      context,
      AppRoutes.completeProfile,
      arguments: {'mode': 'edit', 'user': _lastUser},
    );
    if (changed == true && mounted) await _refresh();
  }

  Future<void> _updatePreference(String key, bool value) async {
    final previousPush = _push;
    final previousSms = _sms;
    try {
      await Services.instance.profile.update({key: value});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('profile.preferenceUpdated'))),
      );
      await _refresh();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _push = previousPush;
        _sms = previousSms;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.firstError())));
    }
  }

  void _handleSmsReminderChanged(bool value) {
    if (value && !_hasSmsPhone()) {
      setState(() => _sms = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.t('profile.smsPhoneRequired')),
          action: SnackBarAction(
            label: context.t('complete.editProfile'),
            onPressed: _editProfile,
          ),
        ),
      );
      return;
    }
    setState(() => _sms = value);
    _updatePreference('sms_reminders_enabled', value);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('profile.languageUpdated'))),
      );
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
      ).showSnackBar(SnackBar(content: Text(context.t('profile.photoFailed'))));
    } finally {
      if (mounted) setState(() => _photoUploading = false);
    }
  }

  String? _profilePhotoUrl(User? user) {
    final raw =
        user?.photoUrl ??
        firebase_auth.FirebaseAuth.instance.currentUser?.photoURL;
    if (raw == null || raw.trim().isEmpty) return null;
    return ApiConfig.publicUrl(raw);
  }

  void _showMedicalSummary(User? user) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final scheme = Theme.of(sheetContext).colorScheme;
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xl + MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SheetTitle(
                  icon: Icons.monitor_heart_outlined,
                  title: sheetContext.t('medical.title'),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: scheme.primary.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Text(
                          _text(
                            user?.bloodGroup,
                            fallback: sheetContext.t('common.pending'),
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: scheme.primary,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _text(
                                user?.name,
                                fallback: sheetContext.t('profile.pendingName'),
                              ),
                              style: TextStyle(
                                color: scheme.onSurface,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _text(
                                user?.donorId,
                                fallback: sheetContext.t('common.pending'),
                              ),
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontFamily: 'monospace',
                                fontSize: 12,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _SheetSectionTitle(sheetContext.t('medical.identity')),
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      _SummaryLine(
                        label: sheetContext.t('auth.gender'),
                        value: _text(
                          user?.gender,
                          fallback: sheetContext.t('common.pending'),
                        ),
                      ),
                      _SummaryLine(
                        label: sheetContext.t('auth.dateOfBirth'),
                        value:
                            _formatDate(user?.dateOfBirth) ??
                            sheetContext.t('common.pending'),
                      ),
                      _SummaryLine(
                        label: sheetContext.t('auth.region'),
                        value: _text(
                          user?.region,
                          fallback: sheetContext.t('common.pending'),
                        ),
                      ),
                      _SummaryLine(
                        label: sheetContext.t('auth.phone'),
                        value: _text(
                          user?.phone,
                          fallback: sheetContext.t('common.pending'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _SheetSectionTitle(sheetContext.t('medical.eligibility')),
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      _SummaryLine(
                        label: sheetContext.t('dashboard.nextEligible'),
                        value:
                            _formatDate(user?.nextEligibleDate) ??
                            sheetContext.t('common.pendingMedical'),
                      ),
                      _SummaryLine(
                        label: sheetContext.t('medical.totalDonations'),
                        value: '${user?.totalDonations ?? 0}',
                      ),
                      _SummaryLine(
                        label: sheetContext.t('medical.totalVolume'),
                        value: _volumeLabel(user?.totalVolumeMl),
                      ),
                      _SummaryLine(
                        label: sheetContext.t('medical.preferredCenter'),
                        value: _text(
                          user?.preferredCenter,
                          fallback: sheetContext.t('common.pending'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        Navigator.pushNamed(context, AppRoutes.donorCard);
                      },
                      icon: const Icon(Icons.qr_code_rounded),
                      label: Text(sheetContext.t('medical.openCard')),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _editProfile();
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(sheetContext.t('profile.editDetails')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEmergencyContact(User? user) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
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
              _SheetTitle(
                icon: Icons.contact_emergency_outlined,
                title: sheetContext.t('profile.emergencyContact'),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                sheetContext.t('profile.emergencySubtitle'),
                style: TextStyle(
                  color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    _SummaryLine(
                      label: sheetContext.t('complete.emergencyName'),
                      value: _text(
                        user?.emergencyContactName,
                        fallback: sheetContext.t('profile.noEmergencyContact'),
                      ),
                    ),
                    _SummaryLine(
                      label: sheetContext.t('complete.emergencyPhone'),
                      value: _text(
                        user?.emergencyContactPhone,
                        fallback: sheetContext.t('common.pending'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _editProfile();
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(sheetContext.t('profile.editDetails')),
                ),
              ),
            ],
          ),
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
                child: Text(actionLabel ?? context.t('common.done')),
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
            onPressed: _editProfile,
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
                ? (snapshot.error as ApiException).safeMessage
                : context.t('profile.loadFailed');
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  EmptyState(
                    icon: Icons.person_off_outlined,
                    title: context.t('profile.unavailable'),
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
                  photoUrl: _profilePhotoUrl(user),
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
                        onTap: () => _showEmergencyContact(user),
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
                        onChanged: _handleSmsReminderChanged,
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
                          title: context.t('profile.faq'),
                          icon: Icons.help_outline_rounded,
                          message: context.t('profile.faqMessage'),
                        ),
                      ),
                      _Divider(scheme: scheme),
                      _Row(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: _copy('contactSupport'),
                        onTap: () => _showInfoSheet(
                          title: context.t('profile.contactSupport'),
                          icon: Icons.chat_bubble_outline_rounded,
                          message: context.t('profile.contactMessage'),
                          actionLabel: context.t('dashboard.findCenter'),
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
                          title: context.t('profile.privacy'),
                          icon: Icons.privacy_tip_outlined,
                          message: context.t('profile.privacyMessage'),
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
    required this.photoUrl,
    required this.uploadingPhoto,
    required this.onPhotoTap,
  });

  final ColorScheme scheme;
  final User? user;
  final String? photoUrl;
  final bool uploadingPhoto;
  final VoidCallback? onPhotoTap;

  @override
  Widget build(BuildContext context) {
    final isDark = scheme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF191113), const Color(0xFF0E0E10)]
              : [const Color(0xFFFFF7F7), const Color(0xFFFFFFFF)],
        ),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: isDark ? 0.18 : 0.07),
            blurRadius: isDark ? 0 : 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ProfileAvatar(
                  scheme: scheme,
                  photoUrl: photoUrl,
                  uploading: uploadingPhoto,
                  onTap: onPhotoTap,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _text(
                          user?.name,
                          fallback: context.t('profile.pendingName'),
                        ),
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                          height: 1.1,
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
            _ProfileStatusBadge(user: user, scheme: scheme),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: context.t('profile.blood'),
                    value: _text(
                      user?.bloodGroup,
                      fallback: context.t('common.pending'),
                    ),
                    scheme: scheme,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _Metric(
                    label: context.t('dashboard.donations'),
                    value: '${user?.totalDonations ?? 0}',
                    scheme: scheme,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _Metric(
                    label: context.t('profile.donorPoints'),
                    value: '${user?.loyaltyPoints ?? 0}',
                    scheme: scheme,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _text(String? value, {required String fallback}) {
    if (value == null || value.trim().isEmpty) return fallback;
    return value;
  }
}

class _ProfileStatusBadge extends StatelessWidget {
  const _ProfileStatusBadge({required this.user, required this.scheme});

  final User? user;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final complete = user?.isDonorProfileComplete == true;
    final color = complete ? AppStatus.success : scheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.pill,
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            complete ? Icons.verified_outlined : Icons.pending_actions_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 7),
          Text(
            complete
                ? context.t('profile.complete')
                : context.t('profile.needsDetails'),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
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
    Widget content;
    if (hasPhoto) {
      content = ClipOval(
        child: Image.network(
          photoUrl!,
          width: 76,
          height: 76,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Icon(
            Icons.person_outline_rounded,
            color: scheme.onSurfaceVariant,
            size: 32,
          ),
        ),
      );
    } else {
      content = Icon(
        Icons.person_outline_rounded,
        color: scheme.onSurfaceVariant,
        size: 32,
      );
    }

    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 76,
            height: 76,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              shape: BoxShape.circle,
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.25),
                width: 2,
              ),
            ),
            child: uploading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: scheme.primary,
                    ),
                  )
                : content,
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

class _SheetTitle extends StatelessWidget {
  const _SheetTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.13),
            borderRadius: AppRadius.chip,
          ),
          child: Icon(icon, color: scheme.primary, size: 22),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _SheetSectionTitle extends StatelessWidget {
  const _SheetSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.7,
        ),
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
  final months = LanguageController.code.value == 'sw'
      ? const [
          'Jan',
          'Feb',
          'Mac',
          'Apr',
          'Mei',
          'Jun',
          'Jul',
          'Ago',
          'Sep',
          'Okt',
          'Nov',
          'Des',
        ]
      : const [
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

String _volumeLabel(int? volumeMl) {
  if (volumeMl == null || volumeMl <= 0) {
    return AppStrings.text('common.pending', LanguageController.code.value);
  }
  if (volumeMl >= 1000) {
    final liters = volumeMl / 1000;
    return '${liters.toStringAsFixed(liters >= 10 ? 0 : 1)} L';
  }
  return '$volumeMl ml';
}

String? _languageLabel(String? value) {
  final normalized = value?.toLowerCase().trim();
  return switch (normalized) {
    'sw' || 'swahili' || 'kiswahili' => 'Swahili',
    'en' || 'english' => 'English',
    _ => null,
  };
}
