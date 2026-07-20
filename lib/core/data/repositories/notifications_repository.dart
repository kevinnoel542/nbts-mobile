import 'package:nbts/core/api/api_client.dart';
import 'package:nbts/core/data/models/json_utils.dart';
import 'package:nbts/core/data/models/user_notification.dart';

class NotificationsRepository {
  NotificationsRepository({required ApiClient api}) : _api = api;
  final ApiClient _api;

  Future<List<UserNotification>> fetchAll() async {
    final response = await _api.get('/notifications');
    return readListPayload(
      response,
    ).map(UserNotification.fromJson).toList(growable: false);
  }

  Future<int> unreadCount() async {
    final response = await _api.get('/notifications/unread-count');
    final payload = readObjectPayload(response);
    return readInt(payload, ['unread_count', 'count', 'total']) ?? 0;
  }

  Future<int> markAllRead() async {
    final response = await _api.post('/notifications/mark-all-read');
    final payload = readObjectPayload(response);
    return readInt(payload, ['unread_count', 'count', 'total']) ?? 0;
  }

  Future<void> markRead(int id) async {
    await _api.post('/notifications/$id/read');
  }

  Future<void> delete(int id) async {
    await _api.delete('/notifications/$id');
  }

  Future<void> registerToken({
    required String token,
    required String deviceType,
  }) async {
    try {
      await _api.post(
        '/notifications/register-token',
        body: {'token': token, 'device_type': deviceType},
      );
    } on ApiException catch (e) {
      final duplicateToken =
          e.isValidation &&
          (e.errors?.containsKey('token') ?? false) &&
          e.firstError('token').toLowerCase().contains('already');
      if (!duplicateToken) rethrow;
    }
  }
}
