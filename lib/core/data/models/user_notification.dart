import 'dart:convert';

import 'package:nbts/core/data/models/json_utils.dart';

class UserNotification {
  const UserNotification({
    required this.id,
    required this.title,
    required this.body,
    this.type,
    this.actionUrl,
    this.data = const {},
    this.read = false,
    this.sentAt,
    this.createdAt,
  });

  final int id;
  final String title;
  final String body;
  final String? type;
  final String? actionUrl;
  final Map<String, dynamic> data;
  final bool read;
  final DateTime? sentAt;
  final DateTime? createdAt;

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    return UserNotification(
      id: readInt(json, ['id', 'notification_id']) ?? 0,
      title: readString(json, ['title', 'heading', 'subject']) ?? 'NBTS update',
      body: readString(json, ['body', 'message', 'content']) ?? '',
      type: readString(json, ['type', 'category']),
      actionUrl: readString(json, ['action_url', 'actionUrl', 'url', 'link']),
      data: _readData(json),
      read:
          readBool(json, ['read', 'is_read']) ??
          readDate(json, ['read_at']) != null,
      sentAt: readDate(json, ['sent_at']),
      createdAt: readDate(json, ['created_at']),
    );
  }

  static Map<String, dynamic> _readData(Map<String, dynamic> json) {
    final raw = json['data'] ?? json['payload'] ?? json['metadata'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.cast<String, dynamic>();
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return decoded.cast<String, dynamic>();
      } on FormatException {
        return const {};
      }
    }
    return const {};
  }
}
