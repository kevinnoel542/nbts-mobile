import 'package:flutter/material.dart';
import 'package:nbts/core/api/api_client.dart';
import 'package:nbts/core/api/service_locator.dart';
import 'package:nbts/core/routes/app_routes.dart';
import 'package:nbts/core/theme/app_tokens.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  static const _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  static const _genders = ['Male', 'Female', 'Other'];
  static const _regions = [
    'Arusha', 'Dar es Salaam', 'Dodoma', 'Geita', 'Iringa', 'Kagera',
    'Katavi', 'Kigoma', 'Kilimanjaro', 'Lindi', 'Manyara', 'Mara', 'Mbeya',
    'Morogoro', 'Mtwara', 'Mwanza', 'Njombe', 'Pwani', 'Rukwa', 'Ruvuma',
    'Shinyanga', 'Simiyu', 'Singida', 'Songwe', 'Tabora', 'Tanga',
  ];

  String? _bloodGroup;
  String? _gender;
  String? _region;
  DateTime? _dateOfBirth;
  bool _submitting = false;
  String? _formError;
  Map<String, List<String>>? _fieldErrors;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String? _err(String field) {
    final list = _fieldErrors?[field];
    if (list == null || list.isEmpty) return null;
    return list.first;
  }

  String _formatDob(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(now.year - 80),
      lastDate: DateTime(now.year - 16, now.month, now.day),
      helpText: 'Date of birth',
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _submit() async {
    setState(() {
      _formError = null;
      _fieldErrors = null;
    });

    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_bloodGroup == null || _gender == null || _region == null || _dateOfBirth == null) {
      setState(() => _formError = 'Complete all donor profile fields.');
      return;
    }

    setState(() => _submitting = true);
    try {
      await Services.instance.profile.update({
        'phone': _phoneController.text.trim(),
        'blood_group': _bloodGroup,
        'gender': _gender!.toLowerCase(),
        'region': _region,
        'date_of_birth': _formatDob(_dateOfBirth!),
      });
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.dashboard,
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Complete profile'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            children: [
              Text(
                'Finish your donor profile',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'NBTS needs these details before you can book appointments or use your donor card.',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                enabled: !_submitting,
                decoration: InputDecoration(
                  labelText: 'Phone',
                  hintText: '+255 712 000 000',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  errorText: _err('phone'),
                ),
                validator: (value) => (value == null || value.trim().length < 9)
                    ? 'Enter a valid phone'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _bloodGroup,
                decoration: InputDecoration(
                  labelText: 'Blood group',
                  prefixIcon: const Icon(Icons.water_drop_outlined),
                  errorText: _err('blood_group'),
                ),
                items: _bloodGroups
                    .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                    .toList(),
                onChanged: _submitting ? null : (value) => setState(() => _bloodGroup = value),
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
                    .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                    .toList(),
                onChanged: _submitting ? null : (value) => setState(() => _gender = value),
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
                    .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                    .toList(),
                onChanged: _submitting ? null : (value) => setState(() => _region = value),
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
                    _dateOfBirth == null ? 'Select date' : _formatDob(_dateOfBirth!),
                    style: TextStyle(
                      color: _dateOfBirth == null
                          ? scheme.onSurfaceVariant
                          : scheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              if (_formError != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formError!,
                    style: TextStyle(
                      color: scheme.onErrorContainer,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
