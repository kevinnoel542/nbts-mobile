import 'package:nbts/core/data/models/json_utils.dart';

class Appointment {
  const Appointment({
    required this.id,
    this.scheduledAt,
    this.centerId,
    this.centerName,
    this.status,
    this.notes,
  });

  final int id;
  final DateTime? scheduledAt;
  final int? centerId;
  final String? centerName;
  final String? status;
  final String? notes;

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final center =
        readObject(json, 'blood_center') ?? readObject(json, 'center');
    return Appointment(
      id: readInt(json, ['id', 'appointment_id']) ?? 0,
      scheduledAt: readDate(json, [
        'scheduled_at',
        'scheduled_for',
        'appointment_date',
        'date',
        'starts_at',
      ]),
      centerId:
          readInt(json, ['center_id', 'blood_center_id']) ??
          readInt(center, ['id', 'center_id']),
      centerName:
          readString(json, ['center_name', 'center_name_text', 'location']) ??
          readString(center, ['name', 'center_name', 'title']),
      status: readString(json, ['status', 'state']),
      notes: readString(json, ['notes', 'note', 'remarks']),
    );
  }
}
