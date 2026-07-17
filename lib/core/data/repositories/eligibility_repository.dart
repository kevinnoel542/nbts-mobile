import 'package:nbts/core/api/api_client.dart';
import 'package:nbts/core/data/models/eligibility.dart';
import 'package:nbts/core/data/models/json_utils.dart';

class EligibilityRepository {
  EligibilityRepository({required ApiClient api}) : _api = api;
  final ApiClient _api;

  Future<Eligibility> fetch() async {
    final response = await _api.get('/eligibility');
    final payload = readObjectPayload(response);
    if (payload == null) {
      throw const ApiException('Unexpected eligibility payload');
    }
    return Eligibility.fromJson(payload);
  }
}
