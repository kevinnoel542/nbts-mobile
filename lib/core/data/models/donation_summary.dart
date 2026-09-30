import 'package:nbts/core/data/models/json_utils.dart';

class DonationSummary {
  const DonationSummary({
    required this.totalDonations,
    required this.totalVolumeMl,
    required this.totalVolumeLiters,
    required this.livesTouched,
    required this.livesTouchedIsEstimate,
    this.lastDonation,
  });

  final int totalDonations;
  final int totalVolumeMl;
  final double totalVolumeLiters;
  final DateTime? lastDonation;
  final int livesTouched;
  final bool livesTouchedIsEstimate;

  factory DonationSummary.fromJson(Map<String, dynamic> json) {
    final volumeMl = readInt(json, ['total_volume_ml']) ?? 0;
    return DonationSummary(
      totalDonations: readInt(json, ['total_donations']) ?? 0,
      totalVolumeMl: volumeMl,
      totalVolumeLiters:
          readDouble(json, ['total_volume_liters']) ?? volumeMl / 1000,
      lastDonation: readDate(json, ['last_donation']),
      livesTouched: readInt(json, ['lives_touched']) ?? 0,
      livesTouchedIsEstimate:
          readBool(json, ['lives_touched_is_estimate']) ?? true,
    );
  }
}
