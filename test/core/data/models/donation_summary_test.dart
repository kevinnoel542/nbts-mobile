import 'package:flutter_test/flutter_test.dart';
import 'package:nbts/core/data/models/donation_summary.dart';

void main() {
  test('parses Laravel donation summary fields', () {
    final summary = DonationSummary.fromJson({
      'total_donations': 2,
      'total_volume_ml': 900,
      'total_volume_liters': 0.9,
      'last_donation': '2026-08-20T09:30:00+03:00',
      'lives_touched': 6,
      'lives_touched_is_estimate': true,
    });

    expect(summary.totalDonations, 2);
    expect(summary.totalVolumeMl, 900);
    expect(summary.totalVolumeLiters, 0.9);
    expect(summary.lastDonation, isNotNull);
    expect(summary.livesTouched, 6);
    expect(summary.livesTouchedIsEstimate, isTrue);
  });
}
