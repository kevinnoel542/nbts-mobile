import 'package:nbts/core/data/models/json_utils.dart';

class DonationRecord {
  const DonationRecord({
    required this.id,
    this.date,
    this.centerName,
    this.bloodType,
    this.volumeMl,
    this.status,
    this.donationType,
  });

  final int id;
  final DateTime? date;
  final String? centerName;
  final String? bloodType;
  final int? volumeMl;
  final String? status;
  final String? donationType;

  factory DonationRecord.fromJson(Map<String, dynamic> json) {
    final center = readObject(json, 'blood_center') ?? readObject(json, 'center');
    return DonationRecord(
      id: readInt(json, ['id', 'donation_id']) ?? 0,
      date: readDate(
        json,
        ['donated_at', 'donation_date', 'date', 'created_at'],
      ),
      centerName: readString(
            json,
            ['center_name', 'center_name_text', 'location'],
          ) ??
          readString(center, ['name', 'center_name', 'title']),
      bloodType: readString(json, ['blood_type', 'blood_group', 'type']),
      volumeMl: readInt(json, ['volume_ml', 'volume', 'amount_ml']),
      status: readString(json, ['status', 'state']),
      donationType: readString(json, ['donation_type', 'type_label']),
    );
  }
}
