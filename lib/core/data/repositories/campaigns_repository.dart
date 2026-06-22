import 'package:nbts/core/api/api_client.dart';
import 'package:nbts/core/data/models/campaign.dart';
import 'package:nbts/core/data/models/json_utils.dart';

class CampaignsRepository {
  CampaignsRepository({required ApiClient api}) : _api = api;
  final ApiClient _api;

  Future<List<Campaign>> fetchAll() async {
    final response = await _api.get('/campaigns');
    return readListPayload(response).map(Campaign.fromJson).toList();
  }
}
