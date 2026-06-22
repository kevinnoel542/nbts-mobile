import 'package:nbts/core/api/api_client.dart';
import 'package:nbts/core/api/token_store.dart';
import 'package:nbts/core/data/repositories/appointments_repository.dart';
import 'package:nbts/core/data/repositories/auth_repository.dart';
import 'package:nbts/core/data/repositories/campaigns_repository.dart';
import 'package:nbts/core/data/repositories/centers_repository.dart';
import 'package:nbts/core/data/repositories/donations_repository.dart';
import 'package:nbts/core/data/repositories/profile_repository.dart';

class Services {
  Services._();
  static final Services instance = Services._();

  late final TokenStore tokens = TokenStore.instance;
  late final ApiClient api = ApiClient(tokenProvider: () => tokens.token);

  late final AuthRepository auth = AuthRepository(api: api, tokens: tokens);
  late final ProfileRepository profile = ProfileRepository(api: api);
  late final CentersRepository centers = CentersRepository(api: api);
  late final DonationsRepository donations = DonationsRepository(api: api);
  late final AppointmentsRepository appointments =
      AppointmentsRepository(api: api);
  late final CampaignsRepository campaigns = CampaignsRepository(api: api);

  Future<void> init() async {
    await tokens.load();
  }
}
