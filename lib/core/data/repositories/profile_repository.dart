import 'package:nbts/core/api/api_client.dart';
import 'package:nbts/core/data/models/json_utils.dart';
import 'package:nbts/core/data/models/user.dart';

class ProfileRepository {
  ProfileRepository({required ApiClient api}) : _api = api;
  final ApiClient _api;

  Future<User> fetch() async {
    final response = await _api.get('/profile');
    final payload = readObjectPayload(response);
    if (payload == null) {
      throw const ApiException('Unexpected profile payload');
    }
    return User.fromJson(payload);
  }
}
