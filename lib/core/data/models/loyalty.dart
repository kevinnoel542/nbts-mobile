import 'package:nbts/core/data/models/json_utils.dart';

class LoyaltySummary {
  const LoyaltySummary({
    required this.points,
    required this.tier,
    required this.totalDonations,
    this.rank,
    this.badges = const [],
    this.rewards = const [],
  });

  final int points;
  final String tier;
  final int totalDonations;
  final int? rank;
  final List<LoyaltyAward> badges;
  final List<LoyaltyAward> rewards;

  factory LoyaltySummary.fromJson(Map<String, dynamic> json) {
    return LoyaltySummary(
      points: readInt(json, ['points', 'loyalty_points']) ?? 0,
      tier: readString(json, ['tier', 'loyalty_tier']) ?? 'Pending',
      totalDonations: readInt(json, ['total_donations']) ?? 0,
      rank: readInt(json, ['rank']),
      badges: _awards(json['badges']),
      rewards: _awards(json['rewards']),
    );
  }

  static List<LoyaltyAward> _awards(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => LoyaltyAward.fromJson(item.cast<String, dynamic>()))
        .toList();
  }
}

class LoyaltyAward {
  const LoyaltyAward({
    required this.id,
    required this.name,
    this.description,
    this.status,
    this.awardedAt,
  });

  final int id;
  final String name;
  final String? description;
  final String? status;
  final DateTime? awardedAt;

  factory LoyaltyAward.fromJson(Map<String, dynamic> json) {
    return LoyaltyAward(
      id: readInt(json, ['id']) ?? 0,
      name: readString(json, ['name', 'title']) ?? 'Recognition',
      description: readString(json, ['description', 'summary']),
      status: readString(json, ['status']),
      awardedAt: readDate(json, ['awarded_at']),
    );
  }
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.id,
    required this.rank,
    required this.displayName,
    required this.donationCount,
    required this.tier,
    required this.isCurrentUser,
  });

  final int id;
  final int rank;
  final String displayName;
  final int donationCount;
  final String tier;
  final bool isCurrentUser;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      id: readInt(json, ['id']) ?? 0,
      rank: readInt(json, ['rank']) ?? 0,
      displayName: readString(json, ['display_name']) ?? 'Donor',
      donationCount: readInt(json, ['donation_count']) ?? 0,
      tier: readString(json, ['loyalty_tier', 'tier']) ?? 'Pending',
      isCurrentUser: readBool(json, ['is_current_user']) ?? false,
    );
  }
}
