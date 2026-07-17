import 'package:flutter/material.dart';
import 'package:nbts/core/localization/app_language.dart';
import 'package:nbts/core/api/api_client.dart';
import 'package:nbts/core/api/service_locator.dart';
import 'package:nbts/core/routes/app_routes.dart';
import 'package:nbts/features/auth/models/social_auth_provider.dart';
import 'package:nbts/features/auth/services/firebase_social_auth_service.dart';
import 'package:nbts/features/auth/widgets/social_auth_section.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;
  String? _formError;

  void _showError(String message) {
    setState(() => _formError = message);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _startSocialAuth(SocialAuthProvider provider) async {
    setState(() {
      _submitting = true;
      _formError = null;
    });
    try {
      final firebaseResult = await FirebaseSocialAuthService.signIn(provider);
      if (firebaseResult == null) {
        if (!mounted) return;
        _showError('${provider.label} sign-in was cancelled.');
        return;
      }

      await Services.instance.auth.loginWithFirebase(
        provider: firebaseResult.provider,
        firebaseIdToken: firebaseResult.idToken,
        email: firebaseResult.email,
        name: firebaseResult.name,
        photoUrl: firebaseResult.photoUrl,
        uid: firebaseResult.uid,
      );
      final user = await Services.instance.auth.fetchCurrentUser();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        user.isDonorProfileComplete
            ? AppRoutes.dashboard
            : AppRoutes.completeProfile,
        (_) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      _showError(e.firstError());
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submit() async {
    final id = _identifierController.text.trim();
    final pw = _passwordController.text;
    if (id.isEmpty || pw.isEmpty) {
      setState(() => _formError = 'Enter your email or phone and password.');
      return;
    }

    setState(() {
      _submitting = true;
      _formError = null;
    });
    try {
      await Services.instance.auth.login(identifier: id, password: pw);
      final user = await Services.instance.auth.fetchCurrentUser();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        user.isDonorProfileComplete
            ? AppRoutes.dashboard
            : AppRoutes.completeProfile,
        (_) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      _showError(e.firstError());
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  InputDecoration _fieldDecoration({
    required ColorScheme scheme,
    required IconData icon,
    required String hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      prefixIcon: Icon(icon, size: 21),
      suffixIcon: suffixIcon,
      hintText: hintText,
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.primary, width: 1.6),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            Text(
              context.t('auth.signIn'),
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.t('auth.loginSubtitle'),
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              context.t('auth.emailPhone'),
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _identifierController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              enabled: !_submitting,
              decoration: _fieldDecoration(
                scheme: scheme,
                icon: Icons.alternate_email_rounded,
                hintText: context.t('auth.emailPhoneHint'),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.t('auth.password'),
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: _obscure,
              enabled: !_submitting,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: _fieldDecoration(
                scheme: scheme,
                icon: Icons.lock_outline_rounded,
                hintText: context.t('auth.password'),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            if (_formError != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 18,
                      color: scheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formError!,
                        style: TextStyle(
                          color: scheme.onErrorContainer,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(58),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                  : Text(context.t('auth.signIn')),
            ),

            const SizedBox(height: 24),
            SocialAuthSection(
              enabled: !_submitting,
              onProviderPressed: _startSocialAuth,
            ),
            const SizedBox(height: 28),
            Center(
              child: TextButton(
                onPressed: _submitting
                    ? null
                    : () => Navigator.pushNamed(context, AppRoutes.register),
                child: Text(context.t('auth.newAccount')),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                context.t('auth.privacyAccept'),
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
