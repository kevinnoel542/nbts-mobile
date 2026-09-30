import 'package:nbts/core/api/api_client.dart';
import 'package:nbts/core/data/models/donation_record.dart';
import 'package:nbts/core/data/models/donation_summary.dart';
import 'package:nbts/core/data/models/json_utils.dart';

class DonationsRepository {
  DonationsRepository({required ApiClient api}) : _api = api;
  final ApiClient _api;

  Future<List<DonationRecord>> fetchAll() async {
    final response = await _api.get(
      '/donations',
      queryParameters: const {'per_page': 50},
    );
    return readListPayload(response).map(DonationRecord.fromJson).toList();
  }

  Future<DonationSummary> fetchSummary() async {
    final response = await _api.get('/donations/summary');
    final payload = readObjectPayload(response);
    if (payload == null) {
      throw const ApiException('Unexpected donation summary response');
    }
    return DonationSummary.fromJson(payload);
  }
}
