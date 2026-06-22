import 'package:nbts/core/api/api_client.dart';
import 'package:nbts/core/data/models/donation_record.dart';
import 'package:nbts/core/data/models/json_utils.dart';

class DonationsRepository {
  DonationsRepository({required ApiClient api}) : _api = api;
  final ApiClient _api;

  Future<List<DonationRecord>> fetchAll() async {
    final response = await _api.get('/donations');
    return readListPayload(response).map(DonationRecord.fromJson).toList();
  }
}
