import 'package:nbts/core/data/models/json_utils.dart';

class User {
  const User({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.bloodGroup,
    this.gender,
    this.region,
    this.dateOfBirth,
    this.donorId,
    this.preferredCenter,
    this.loyaltyTier,
    this.loyaltyPoints,
    this.totalDonations,
    this.totalVolumeMl,
    this.nextEligibleDate,
    this.profileComplete,
  });

  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? bloodGroup;
  final String? gender;
  final String? region;
  final DateTime? dateOfBirth;
  final String? donorId;
  final String? preferredCenter;
  final String? loyaltyTier;
  final int? loyaltyPoints;
  final int? totalDonations;
  final int? totalVolumeMl;
  final DateTime? nextEligibleDate;
  final bool? profileComplete;

  bool get isDonorProfileComplete =>
      profileComplete ??
      (_hasText(phone) &&
          _hasText(bloodGroup) &&
          _hasText(gender) &&
          _hasText(region) &&
          dateOfBirth != null);

  factory User.fromJson(Map<String, dynamic> json) {
    final donorProfile = readObject(json, 'donor_profile');
    final profile = readObject(json, 'profile') ?? donorProfile;
    return User(
      id: readInt(json, ['id', 'user_id']) ?? 0,
      name: readString(json, ['name', 'full_name', 'display_name']) ?? '',
      email: readString(json, ['email']),
      phone: readString(json, ['phone', 'phone_number', 'mobile']),
      bloodGroup: readString(json, ['blood_group', 'blood_type', 'bloodGroup']),
      gender: readString(json, ['gender', 'sex']),
      region: readString(json, ['region', 'location', 'city']),
      dateOfBirth: readDate(json, ['date_of_birth', 'dob', 'birth_date']),
      donorId:
          readString(json, ['donor_id', 'donorId', 'nbts_id']) ??
          readString(profile, ['donor_id', 'donorId', 'nbts_id']),
      preferredCenter: readString(json, [
        'preferred_center',
        'preferred_center_name',
        'center',
      ]),
      loyaltyTier: readString(json, ['loyalty_tier', 'tier']),
      loyaltyPoints: readInt(json, ['loyalty_points', 'points']),
      totalDonations:
          readInt(json, [
            'total_donations',
            'donations_count',
            'donation_count',
          ]) ??
          readInt(profile, ['total_donations', 'donations_count']),
      totalVolumeMl: readInt(json, [
        'total_volume_ml',
        'total_volume',
        'volume_ml',
      ]),
      nextEligibleDate:
          readDate(json, [
            'next_eligible_date',
            'next_eligible_at',
            'eligible_date',
          ]) ??
          readDate(profile, [
            'next_eligible_donation_date',
            'next_eligible_date',
            'eligible_date',
          ]),
      profileComplete:
          readBool(json, [
            'profile_complete',
            'is_profile_complete',
            'profileComplete',
            'donor_profile_complete',
          ]) ??
          readBool(profile, [
            'profile_complete',
            'is_profile_complete',
            'profileComplete',
            'donor_profile_complete',
          ]),
    );
  }
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
