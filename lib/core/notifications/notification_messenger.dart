import 'package:flutter/material.dart';

final notificationMessengerKey = GlobalKey<ScaffoldMessengerState>();

void showInAppNotification({required String title, required String body}) {
  final messenger = notificationMessengerKey.currentState;
  if (messenger == null) return;

  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(body),
          ],
        ],
      ),
      duration: const Duration(seconds: 5),
    ),
  );
}
