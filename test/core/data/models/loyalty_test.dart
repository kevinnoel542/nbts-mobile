import 'package:flutter_test/flutter_test.dart';
import 'package:nbts/core/data/models/loyalty.dart';

void main() {
  test('parses loyalty, badges, and rewards', () {
    final summary = LoyaltySummary.fromJson({
      'points': 120,
      'tier': 'Silver',
      'total_donations': 4,
      'rank': 8,
      'badges': [
        {'id': 1, 'name': 'First donation'},
      ],
      'rewards': [
        {'id': 2, 'name': 'Recognition certificate', 'status': 'available'},
      ],
    });

    expect(summary.points, 120);
    expect(summary.tier, 'Silver');
    expect(summary.rank, 8);
    expect(summary.badges.single.name, 'First donation');
    expect(summary.rewards.single.status, 'available');
  });
}
