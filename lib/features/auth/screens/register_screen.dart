import 'package:flutter/material.dart';
import 'package:nbts/core/api/api_client.dart';
import 'package:nbts/core/api/service_locator.dart';
import 'package:nbts/core/routes/app_routes.dart';
import 'package:nbts/core/theme/app_tokens.dart';
import 'package:nbts/features/auth/models/social_auth_provider.dart';
import 'package:nbts/features/auth/services/firebase_social_auth_service.dart';
import 'package:nbts/features/auth/widgets/social_auth_section.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  static const _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];
  static const _genders = ['Male', 'Female', 'Other'];
  static const _regions = [
    'Arusha',
    'Dar es Salaam',
    'Dodoma',
    'Geita',
    'Iringa',
    'Kagera',
    'Katavi',
    'Kigoma',
    'Kilimanjaro',
    'Lindi',
    'Manyara',
    'Mara',
    'Mbeya',
    'Morogoro',
    'Mtwara',
    'Mwanza',
    'Njombe',
    'Pwani',
    'Rukwa',
    'Ruvuma',
    'Shinyanga',
    'Simiyu',
    'Singida',
    'Songwe',
    'Tabora',
    'Tanga',
  ];

  String? _bloodGroup;
  String? _gender;
  String? _region;
  DateTime? _dateOfBirth;
  bool _obscure = true;
  bool _accepted = false;
  bool _submitting = false;
  String? _formError;
  Map<String, List<String>>? _fieldErrors;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _startSocialAuth(SocialAuthProvider provider) async {
    setState(() {
      _submitting = true;
      _formError = null;
      _fieldErrors = null;
    });
    try {
      final firebaseResult = await FirebaseSocialAuthService.signIn(provider);
      if (firebaseResult == null) {
        if (!mounted) return;
        setState(() => _formError = '${provider.label} sign-up was cancelled.');
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
      setState(() {
        _fieldErrors = e.errors;
        _formError = e.errors == null ? e.message : e.firstError();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _formError = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _err(String field) {
    final list = _fieldErrors?[field];
    if (list == null || list.isEmpty) return null;
    return list.first;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _dateOfBirth ?? DateTime(now.year - 25, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 80),
      lastDate: DateTime(now.year - 16, now.month, now.day),
      helpText: 'Date of birth',
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  String _formatDob(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    setState(() => _formError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_bloodGroup == null ||
        _gender == null ||
        _region == null ||
        _dateOfBirth == null) {
      setState(() => _formError = 'Complete all donor profile fields.');
      return;
    }
    if (!_accepted) {
      setState(() => _formError = 'Accept the terms to continue.');
      return;
    }

    setState(() {
      _submitting = true;
      _fieldErrors = null;
    });
    try {
      await Services.instance.auth.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        bloodGroup: _bloodGroup!,
        gender: _gender!,
        region: _region!,
        dateOfBirth: _formatDob(_dateOfBirth!),
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
      setState(() {
        _fieldErrors = e.errors;
        _formError = e.errors == null ? e.message : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _formError = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _submitting ? null : () => Navigator.pop(context),
        ),
        title: const Text('Create account'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            children: [
              Text(
                'Donor registration',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tell us a bit about you to set up your NBTS donor profile.',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SocialAuthSection(
                enabled: !_submitting,
                onProviderPressed: _startSocialAuth,
              ),
              const SizedBox(height: AppSpacing.xl),
              _SectionLabel('Account'),
              const SizedBox(height: 12),
              _Field(
                controller: _nameController,
                label: 'Full name',
                icon: Icons.person_outline,
                errorText: _err('name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
                enabled: !_submitting,
              ),
              const SizedBox(height: 12),
              _Field(
                controller: _emailController,
                label: 'Email (optional)',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                errorText: _err('email'),
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return null;
                  if (!t.contains('@') || !t.contains('.')) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
                enabled: !_submitting,
              ),
              const SizedBox(height: 12),
              _Field(
                controller: _phoneController,
                label: 'Phone',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                hint: '+255 712 000 000',
                errorText: _err('phone'),
                validator: (v) => (v == null || v.trim().length < 9)
                    ? 'Enter a valid phone'
                    : null,
                enabled: !_submitting,
              ),
              const SizedBox(height: 12),
              _Field(
                controller: _passwordController,
                label: 'Password',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscure,
                errorText: _err('password'),
                validator: (v) => (v == null || v.length < 8)
                    ? 'Use at least 8 characters'
                    : null,
                enabled: !_submitting,
                suffix: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _SectionLabel('Donor profile'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _bloodGroup,
                decoration: InputDecoration(
                  labelText: 'Blood group',
                  prefixIcon: const Icon(Icons.water_drop_outlined),
                  errorText: _err('blood_group'),
                ),
                items: _bloodGroups
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: _submitting
                    ? null
                    : (v) => setState(() => _bloodGroup = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: const Icon(Icons.wc_outlined),
                  errorText: _err('gender'),
                ),
                items: _genders
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: _submitting
                    ? null
                    : (v) => setState(() => _gender = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _region,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Region',
                  prefixIcon: const Icon(Icons.place_outlined),
                  errorText: _err('region'),
                ),
                items: _regions
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: _submitting
                    ? null
                    : (v) => setState(() => _region = v),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _submitting ? null : _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date of birth',
                    prefixIcon: const Icon(Icons.cake_outlined),
                    errorText: _err('date_of_birth'),
                  ),
                  child: Text(
                    _dateOfBirth == null
                        ? 'Select date'
                        : _formatDob(_dateOfBirth!),
                    style: TextStyle(
                      color: _dateOfBirth == null
                          ? scheme.onSurfaceVariant
                          : scheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              CheckboxListTile(
                value: _accepted,
                onChanged: _submitting
                    ? null
                    : (v) => setState(() => _accepted = v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'I accept the Terms, Privacy Policy and health-data notice.',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
              ),
              if (_formError != null) ...[
                const SizedBox(height: 8),
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
              const SizedBox(height: AppSpacing.lg),
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
                    : const Text('Create account'),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: TextButton(
                  onPressed: _submitting
                      ? null
                      : () => Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.login,
                        ),
                  child: const Text('Already have an account?  Sign in'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.errorText,
    this.validator,
    this.enabled = true,
    this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? errorText;
  final String? Function(String?)? validator;
  final bool enabled;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: enabled,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        errorText: errorText,
      ),
    );
  }
}
