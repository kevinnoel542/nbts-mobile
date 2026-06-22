import 'package:nbts/core/api/api_client.dart';
import 'package:nbts/core/data/models/donation_center.dart';
import 'package:nbts/core/data/models/json_utils.dart';

class CentersRepository {
  CentersRepository({required ApiClient api}) : _api = api;
  final ApiClient _api;

  Future<List<DonationCenter>> fetchAll() async {
    final response = await _api.get('/blood-centers');
    return readListPayload(response).map(DonationCenter.fromJson).toList();
  }
}
