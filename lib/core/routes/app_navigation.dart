import 'package:flutter/material.dart';
import 'package:nbts/core/routes/app_routes.dart';

final appNavigatorKey = GlobalKey<NavigatorState>();

void openExpiredSessionLogin() {
  final navigator = appNavigatorKey.currentState;
  if (navigator == null) return;

  navigator.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
}
