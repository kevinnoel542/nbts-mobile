import 'dart:async';
import 'package:nbts/core/api/api_client.dart';
import 'package:nbts/core/api/token_store.dart';
import 'package:nbts/core/notifications/notification_service.dart';
import 'package:nbts/core/data/repositories/appointments_repository.dart';
import 'package:nbts/core/data/repositories/articles_repository.dart';
import 'package:nbts/core/data/repositories/auth_repository.dart';
import 'package:nbts/core/data/repositories/campaigns_repository.dart';
import 'package:nbts/core/data/repositories/centers_repository.dart';
import 'package:nbts/core/data/repositories/donations_repository.dart';
import 'package:nbts/core/data/repositories/donor_card_repository.dart';
import 'package:nbts/core/data/repositories/eligibility_repository.dart';
import 'package:nbts/core/data/repositories/notifications_repository.dart';
import 'package:nbts/core/data/repositories/profile_repository.dart';

class Services {
  Services._();
  static final Services instance = Services._();

  late final TokenStore tokens = TokenStore.instance;
  late final ApiClient api = ApiClient(tokenProvider: () => tokens.token);

  late final AuthRepository auth = AuthRepository(
    api: api,
    tokens: tokens,
    onAuthenticated: notificationService.registerDeviceToken,
  );
  late final ProfileRepository profile = ProfileRepository(api: api);
  late final CentersRepository centers = CentersRepository(api: api);
  late final DonationsRepository donations = DonationsRepository(api: api);
  late final AppointmentsRepository appointments = AppointmentsRepository(
    api: api,
  );
  late final CampaignsRepository campaigns = CampaignsRepository(api: api);
  late final ArticlesRepository articles = ArticlesRepository(api: api);
  late final DonorCardRepository donorCard = DonorCardRepository(api: api);
  late final EligibilityRepository eligibility = EligibilityRepository(
    api: api,
  );
  late final NotificationsRepository notifications = NotificationsRepository(
    api: api,
  );
  late final NotificationService notificationService = NotificationService(
    notifications: notifications,
  );

  Future<void>? _initFuture;

  Future<void> init() {
    return _initFuture ??= _init();
  }

  Future<void> _init() async {
    await tokens.load();
    unawaited(notificationService.init(authenticated: tokens.isAuthenticated));
  }
}
