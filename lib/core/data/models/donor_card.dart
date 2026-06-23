import 'dart:convert';

import 'package:nbts/core/data/models/json_utils.dart';

class DonorCard {
  const DonorCard({
    required this.donorId,
    required this.qrPayloadText,
    this.name,
    this.phone,
    this.bloodGroup,
    this.bloodGroupVerified,
    this.region,
    this.preferredCenter,
    this.totalDonations,
    this.lastDonation,
    this.nextEligibleDate,
    this.eligibilityStatus,
    this.loyaltyPoints,
    this.loyaltyTier,
    this.qrExpiresAt,
  });

  final String donorId;
  final String qrPayloadText;
  final String? name;
  final String? phone;
  final String? bloodGroup;
  final bool? bloodGroupVerified;
  final String? region;
  final String? preferredCenter;
  final int? totalDonations;
  final DateTime? lastDonation;
  final DateTime? nextEligibleDate;
  final String? eligibilityStatus;
  final int? loyaltyPoints;
  final String? loyaltyTier;
  final DateTime? qrExpiresAt;

  factory DonorCard.fromJson(Map<String, dynamic> json) {
    final donor = readObject(json, 'donor');
    final stats = readObject(json, 'stats');
    final qrPayload = readObject(json, 'qr_payload');
    final donorId = readString(json, ['donor_id']) ??
        readString(qrPayload, ['donor_id']) ??
        'Pending NBTS ID';

    return DonorCard(
      donorId: donorId,
      qrPayloadText: qrPayload == null ? donorId : jsonEncode(qrPayload),
      name: readString(donor, ['name']),
      phone: readString(donor, ['phone']),
      bloodGroup: readString(donor, ['blood_group', 'blood_type']),
      bloodGroupVerified: readBool(donor, ['blood_group_verified']),
      region: readString(donor, ['region']),
      preferredCenter: readString(donor, ['preferred_center']),
      totalDonations: readInt(stats, ['total_donations', 'donations_count']),
      lastDonation: readDate(stats, ['last_donation']),
      nextEligibleDate: readDate(
        stats,
        ['next_eligible_donation_date', 'next_eligible_date'],
      ),
      eligibilityStatus: readString(stats, ['eligibility_status', 'status']),
      loyaltyPoints: readInt(stats, ['loyalty_points', 'points']),
      loyaltyTier: readString(stats, ['loyalty_tier', 'tier']),
      qrExpiresAt: readDate(json, ['qr_expires_at']),
    );
  }
}