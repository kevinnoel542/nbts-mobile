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
    return Appointment(
      id: readInt(json, ['id', 'appointment_id']) ?? 0,
      scheduledAt: readDate(
        json,
        [
          'scheduled_at',
          'scheduled_for',
          'appointment_date',
          'date',
          'starts_at',
        ],
      ),
      centerId: readInt(json, ['center_id', 'blood_center_id']),
      centerName: readString(
        json,
        ['center_name', 'center', 'blood_center', 'location'],
      ),
      status: readString(json, ['status', 'state']),
      notes: readString(json, ['notes', 'note', 'remarks']),
    );
  }
}
