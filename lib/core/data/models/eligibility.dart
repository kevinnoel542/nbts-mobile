import 'package:nbts/core/data/models/json_utils.dart';

class Eligibility {
  const Eligibility({
    required this.status,
    required this.eligible,
    required this.message,
    this.reasons = const [],
    this.nextEligibleDate,
  });

  final String status;
  final bool eligible;
  final String message;
  final List<String> reasons;
  final DateTime? nextEligibleDate;

  factory Eligibility.fromJson(Map<String, dynamic> json) {
    return Eligibility(
      status: readString(json, ['status']) ?? 'pending',
      eligible: readBool(json, ['eligible']) ?? false,
      message: readString(json, ['message']) ?? 'Eligibility pending.',
      reasons: readStringList(json, ['reasons']),
      nextEligibleDate: readDate(
        json,
        ['next_eligible_donation_date', 'next_eligible_date'],
      ),
    );
  }
}