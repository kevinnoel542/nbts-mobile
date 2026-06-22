import 'package:nbts/core/data/models/json_utils.dart';

class Campaign {
  const Campaign({
    required this.id,
    required this.title,
    this.summary,
    this.category,
    this.bloodType,
    this.startsAt,
    this.endsAt,
    this.urgent,
  });

  final int id;
  final String title;
  final String? summary;
  final String? category;
  final String? bloodType;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool? urgent;

  factory Campaign.fromJson(Map<String, dynamic> json) {
    return Campaign(
      id: readInt(json, ['id', 'campaign_id']) ?? 0,
      title: readString(json, ['title', 'name', 'heading']) ?? 'Campaign',
      summary: readString(
        json,
        ['summary', 'description', 'body', 'message'],
      ),
      category: readString(json, ['category', 'type', 'tag']),
      bloodType: readString(json, ['blood_type', 'blood_group']),
      startsAt: readDate(json, ['starts_at', 'start_date', 'begin_at']),
      endsAt: readDate(json, ['ends_at', 'end_date', 'expires_at']),
      urgent: readBool(json, ['urgent', 'is_urgent', 'priority_urgent']),
    );
  }
}
