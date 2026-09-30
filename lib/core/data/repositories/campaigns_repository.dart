import 'package:nbts/core/api/api_client.dart';
import 'package:nbts/core/data/models/campaign.dart';
import 'package:nbts/core/data/models/json_utils.dart';

class CampaignsRepository {
  CampaignsRepository({required ApiClient api}) : _api = api;
  final ApiClient _api;

  Future<List<Campaign>> fetchAll() async {
    final response = await _api.get(
      '/campaigns',
      queryParameters: const {'per_page': 50},
    );
    return readListPayload(response).map(Campaign.fromJson).toList();
  }

  Future<List<Campaign>> fetchSchedules() async {
    final response = await _api.get(
      '/schedules',
      queryParameters: const {'per_page': 50},
      authenticated: false,
    );
    return readListPayload(response).map(Campaign.fromJson).toList();
  }
}
