import 'package:nbts/core/api/api_client.dart';
import 'package:nbts/core/data/models/appointment.dart';
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

  Future<Appointment> book({
    required int centerId,
    required DateTime scheduledAt,
    String? notes,
  }) async {
    final response = await _api.post('/appointments', body: {
      'center_id': centerId,
      'blood_center_id': centerId,
      'scheduled_at': scheduledAt.toIso8601String(),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    final payload = readObjectPayload(response);
    if (payload == null) {
      throw const ApiException('Unexpected appointment response');
    }
    return Appointment.fromJson(payload);
  }
}
