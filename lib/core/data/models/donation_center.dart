import 'package:nbts/core/data/models/json_utils.dart';

class DonationCenter {
  const DonationCenter({
    required this.id,
    required this.name,
    this.address,
    this.distanceKm,
    this.hours,
    this.phone,
    this.waitTime,
    this.capacityLabel,
    this.services = const [],
    this.isOpen,
  });

  final int id;
  final String name;
  final String? address;
  final double? distanceKm;
  final String? hours;
  final String? phone;
  final String? waitTime;
  final String? capacityLabel;
  final List<String> services;
  final bool? isOpen;

  factory DonationCenter.fromJson(Map<String, dynamic> json) {
    return DonationCenter(
      id: readInt(json, ['id', 'center_id']) ?? 0,
      name: readString(json, ['name', 'center_name', 'title']) ?? 'Center',
      address: readString(
        json,
        ['address', 'location', 'full_address', 'street'],
      ),
      distanceKm: readDouble(json, ['distance_km', 'distance']),
      hours: readString(
        json,
        ['hours', 'opening_hours', 'working_hours', 'open_hours'],
      ),
      phone: readString(json, ['phone', 'phone_number', 'contact']),
      waitTime: readString(json, ['wait_time', 'estimated_wait']),
      capacityLabel: readString(
        json,
        ['capacity_label', 'capacity', 'availability'],
      ),
      services: readStringList(json, ['services', 'service_list']),
      isOpen: readBool(json, ['is_open', 'open', 'status_open']),
    );
  }
}
