import 'package:flutter/material.dart';
import 'package:nbts/core/api/api_client.dart';
import 'package:nbts/core/api/service_locator.dart';
import 'package:nbts/core/data/models/donation_center.dart';
import 'package:nbts/core/routes/app_routes.dart';
import 'package:nbts/core/theme/app_tokens.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

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
  static const _languages = ['English', 'Swahili'];

  late Future<List<DonationCenter>> _centersFuture;
  String? _bloodGroup;
  String? _gender;
  String? _region;
  int? _preferredCenterId;
  DateTime? _dateOfBirth;
  bool _pushNotifications = true;
  bool _smsReminders = true;
  bool _shareAnonymizedData = false;
  String _language = 'English';
  bool _submitting = false;
  String? _formError;
  Map<String, List<String>>? _fieldErrors;

  @override
  void initState() {
    super.initState();
    final currentUser = Services.instance.auth.user;
    _nameController.text = currentUser?.name ?? '';
    _phoneController.text = currentUser?.phone ?? '';
    _bloodGroup = _matchOption(_bloodGroups, currentUser?.bloodGroup);
    _gender = _matchOption(_genders, currentUser?.gender);
    _region = _matchOption(_regions, currentUser?.region);
    _dateOfBirth = currentUser?.dateOfBirth;
    _centersFuture = Services.instance.centers.fetchAll();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  String? _matchOption(List<String> options, String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.trim().toLowerCase();
    for (final option in options) {
      if (option.toLowerCase() == normalized) return option;
    }
    return null;
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
    if (_bloodGroup == null ||
        _gender == null ||
        _region == null ||
        _dateOfBirth == null) {
      setState(() => _formError = 'Complete all required donor fields.');
      return;
    }

    final address = _addressController.text.trim();
    final emergencyName = _emergencyNameController.text.trim();
    final emergencyPhone = _emergencyPhoneController.text.trim();

    setState(() => _submitting = true);
    try {
      await Services.instance.profile.update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'blood_group': _bloodGroup,
        'gender': _gender!.toLowerCase(),
        'region': _region,
        'date_of_birth': _formatDob(_dateOfBirth!),
        if (address.isNotEmpty) 'address': address,
        if (_preferredCenterId != null)
          'preferred_center_id': _preferredCenterId,
        if (emergencyName.isNotEmpty) 'emergency_contact_name': emergencyName,
        if (emergencyPhone.isNotEmpty)
          'emergency_contact_phone': emergencyPhone,
        'push_notifications_enabled': _pushNotifications,
        'sms_reminders_enabled': _smsReminders,
        'share_anonymized_data': _shareAnonymizedData,
        'language': _language.toLowerCase(),
      });
      await Services.instance.auth.fetchCurrentUser();
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
                'Google or Apple confirms your identity. NBTS still needs donor details before appointments and donor card access.',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const _SectionLabel('Required'),
              const SizedBox(height: 12),
              _Field(
                controller: _nameController,
                label: 'Full name',
                icon: Icons.person_outline,
                enabled: !_submitting,
                errorText: _err('name'),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Enter your full name'
                    : null,
              ),
              const SizedBox(height: 12),
              _Field(
                controller: _phoneController,
                label: 'Phone',
                hint: '+255 712 000 000',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                enabled: !_submitting,
                errorText: _err('phone'),
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
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: _submitting
                    ? null
                    : (value) => setState(() => _bloodGroup = value),
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
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: _submitting
                    ? null
                    : (value) => setState(() => _gender = value),
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
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: _submitting
                    ? null
                    : (value) => setState(() => _region = value),
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
              const SizedBox(height: AppSpacing.xl),
              const _SectionLabel('Optional'),
              const SizedBox(height: 12),
              _Field(
                controller: _addressController,
                label: 'Address',
                icon: Icons.home_outlined,
                enabled: !_submitting,
                errorText: _err('address'),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<DonationCenter>>(
                future: _centersFuture,
                builder: (context, snapshot) {
                  final centers = snapshot.data ?? const <DonationCenter>[];
                  return DropdownButtonFormField<int>(
                    initialValue: _preferredCenterId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Preferred blood center',
                      prefixIcon: const Icon(Icons.local_hospital_outlined),
                      errorText: _err('preferred_center_id'),
                    ),
                    items: centers
                        .map(
                          (center) => DropdownMenuItem(
                            value: center.id,
                            child: Text(center.name),
                          ),
                        )
                        .toList(),
                    hint: Text(
                      snapshot.connectionState == ConnectionState.waiting
                          ? 'Loading centers'
                          : centers.isEmpty
                          ? 'No centers available'
                          : 'Select center',
                    ),
                    onChanged: _submitting || centers.isEmpty
                        ? null
                        : (value) => setState(() => _preferredCenterId = value),
                  );
                },
              ),
              const SizedBox(height: 12),
              _Field(
                controller: _emergencyNameController,
                label: 'Emergency contact name',
                icon: Icons.contact_emergency_outlined,
                enabled: !_submitting,
                errorText: _err('emergency_contact_name'),
              ),
              const SizedBox(height: 12),
              _Field(
                controller: _emergencyPhoneController,
                label: 'Emergency contact phone',
                icon: Icons.call_outlined,
                keyboardType: TextInputType.phone,
                enabled: !_submitting,
                errorText: _err('emergency_contact_phone'),
              ),
              const SizedBox(height: AppSpacing.xl),
              const _SectionLabel('Preferences'),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                value: _pushNotifications,
                onChanged: _submitting
                    ? null
                    : (value) => setState(() => _pushNotifications = value),
                contentPadding: EdgeInsets.zero,
                title: const Text('Push notifications'),
                subtitle: const Text('Appointments and urgent NBTS alerts'),
              ),
              SwitchListTile.adaptive(
                value: _smsReminders,
                onChanged: _submitting
                    ? null
                    : (value) => setState(() => _smsReminders = value),
                contentPadding: EdgeInsets.zero,
                title: const Text('SMS reminders'),
                subtitle: const Text('Donation appointment reminders'),
              ),
              SwitchListTile.adaptive(
                value: _shareAnonymizedData,
                onChanged: _submitting
                    ? null
                    : (value) => setState(() => _shareAnonymizedData = value),
                contentPadding: EdgeInsets.zero,
                title: const Text('Share anonymized data'),
                subtitle: const Text('Helps NBTS planning and donor safety'),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: _languages
                    .map(
                      (value) =>
                          ButtonSegment(value: value, label: Text(value)),
                    )
                    .toList(),
                selected: {_language},
                onSelectionChanged: _submitting
                    ? null
                    : (value) => setState(() => _language = value.first),
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
                    : const Text('Save and continue'),
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
        fontWeight: FontWeight.w800,
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
    this.enabled = true,
    this.errorText,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final TextInputType? keyboardType;
  final bool enabled;
  final String? errorText;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        errorText: errorText,
      ),
    );
  }
}
