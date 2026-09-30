import 'package:nbts/core/api/api_client.dart';
import 'package:nbts/core/data/models/json_utils.dart';
import 'package:nbts/core/data/models/loyalty.dart';

class LoyaltyRepository {
  LoyaltyRepository({required ApiClient api}) : _api = api;

  final ApiClient _api;

  Future<LoyaltySummary> fetchSummary() async {
    final response = await _api.get('/loyalty');
    final payload = readObjectPayload(response);
    if (payload == null) {
      throw const ApiException('Unexpected loyalty response');
    }
    return LoyaltySummary.fromJson(payload);
  }

  Future<List<LeaderboardEntry>> fetchLeaderboard() async {
    final response = await _api.get(
      '/leaderboard',
      queryParameters: const {'period': 'all_time', 'per_page': 50},
    );
    return readListPayload(response).map(LeaderboardEntry.fromJson).toList();
  }
}
