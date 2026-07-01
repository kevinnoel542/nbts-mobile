import 'package:nbts/core/api/api_client.dart';
import 'package:nbts/core/data/models/appointment.dart';
import 'package:nbts/core/data/models/appointment_slot.dart';
import 'package:nbts/core/data/models/json_utils.dart';

class AppointmentsRepository {
  AppointmentsRepository({required ApiClient api}) : _api = api;
  final ApiClient _api;

  Future<List<Appointment>> fetchAll() async {
    final response = await _api.get('/appointments');
    return readListPayload(response).map(Appointment.fromJson).toList();
  }

  Future<Appointment?> fetchUpcoming() async {
    try {
      final response = await _api.get('/appointments/upcoming');
      final payload = readObjectPayload(response);
      if (payload != null && payload.isNotEmpty) {
        return Appointment.fromJson(payload);
      }
      final list = readListPayload(response);
      if (list.isNotEmpty) return Appointment.fromJson(list.first);
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<List<AppointmentSlot>> fetchSlots({
    required int centerId,
    required DateTime date,
  }) async {
    final day = _formatDate(date);
    final response = await _api.get(
      '/blood-centers/$centerId/available-slots?date=$day',
    );
    return readListPayload(response).map(AppointmentSlot.fromJson).toList();
  }

  Future<Appointment> reschedule({
    required int appointmentId,
    required int centerId,
    required DateTime scheduledAt,
    String? notes,
  }) async {
    final response = await _api.put(
      '/appointments/$appointmentId',
      body: {
        'blood_center_id': centerId,
        'scheduled_at': scheduledAt.toIso8601String(),
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    final payload = readObjectPayload(response);
    if (payload == null) {
      throw const ApiException('Unexpected appointment response');
    }
    return Appointment.fromJson(payload);
  }

  Future<Appointment> cancel(int appointmentId) async {
    final response = await _api.post('/appointments/$appointmentId/cancel');
    final payload = readObjectPayload(response);
    if (payload == null) {
      throw const ApiException('Unexpected appointment response');
    }
    return Appointment.fromJson(payload);
  }

  Future<Appointment> book({
    required int centerId,
    required DateTime scheduledAt,
    String? notes,
  }) async {
    final response = await _api.post(
      '/appointments',
      body: {
        'center_id': centerId,
        'blood_center_id': centerId,
        'scheduled_at': scheduledAt.toIso8601String(),
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    final payload = readObjectPayload(response);
    if (payload == null) {
      throw const ApiException('Unexpected appointment response');
    }
    return Appointment.fromJson(payload);
  }

  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
