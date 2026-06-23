import 'package:nbts/core/api/api_client.dart';
import 'package:nbts/core/data/models/donor_card.dart';
import 'package:nbts/core/data/models/json_utils.dart';

class DonorCardRepository {
  DonorCardRepository({required ApiClient api}) : _api = api;
  final ApiClient _api;

  Future<DonorCard> fetch() async {
    final response = await _api.get('/donor-card');
    final payload = readObjectPayload(response);
    if (payload == null) {
      throw const ApiException('Unexpected donor card payload');
    }
    return DonorCard.fromJson(payload);
  }
}