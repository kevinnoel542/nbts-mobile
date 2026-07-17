import 'package:nbts/core/data/models/json_utils.dart';

class UserNotification {
  const UserNotification({
    required this.id,
    required this.title,
    required this.body,
    this.type,
    this.read = false,
    this.sentAt,
    this.createdAt,
  });

  final int id;
  final String title;
  final String body;
  final String? type;
  final bool read;
  final DateTime? sentAt;
  final DateTime? createdAt;

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    return UserNotification(
      id: readInt(json, ['id', 'notification_id']) ?? 0,
      title: readString(json, ['title', 'heading', 'subject']) ?? 'NBTS update',
      body: readString(json, ['body', 'message', 'content']) ?? '',
      type: readString(json, ['type', 'category']),
      read:
          readBool(json, ['read', 'is_read']) ??
          readDate(json, ['read_at']) != null,
      sentAt: readDate(json, ['sent_at']),
      createdAt: readDate(json, ['created_at']),
    );
  }
}
