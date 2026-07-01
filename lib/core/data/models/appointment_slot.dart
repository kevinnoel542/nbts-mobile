import 'package:flutter/material.dart';
import 'package:nbts/core/data/models/json_utils.dart';

class AppointmentSlot {
  const AppointmentSlot({
    required this.time,
    this.available = true,
    this.reason,
  });

  final TimeOfDay time;
  final bool available;
  final String? reason;

  factory AppointmentSlot.fromJson(Map<String, dynamic> json) {
    final rawTime =
        readString(json, [
          'time',
          'slot_time',
          'starts_at',
          'start_time',
          'scheduled_time',
        ]) ??
        '00:00';

    return AppointmentSlot(
      time: parseSlotTime(rawTime) ?? const TimeOfDay(hour: 0, minute: 0),
      available: readBool(json, ['available', 'is_available', 'open']) ?? true,
      reason: readString(json, ['reason', 'message', 'status_label']),
    );
  }

  String get value {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

TimeOfDay? parseSlotTime(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;

  final dateTime = DateTime.tryParse(trimmed);
  if (dateTime != null) {
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }

  final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(trimmed);
  if (match == null) return null;

  final hour = int.tryParse(match.group(1)!);
  final minute = int.tryParse(match.group(2)!);
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  return TimeOfDay(hour: hour, minute: minute);
}
