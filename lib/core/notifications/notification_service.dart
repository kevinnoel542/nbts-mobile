import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nbts/core/data/repositories/notifications_repository.dart';
import 'package:nbts/core/notifications/notification_counter.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp().timeout(const Duration(seconds: 8));
}

class NotificationService {
  NotificationService({required NotificationsRepository notifications})
    : _notifications = notifications;

  static const _nativeNotifications = MethodChannel('nbts/notifications');

  final NotificationsRepository _notifications;
  FirebaseMessaging? _messaging;

  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundMessageSub;
  bool _firebaseReady = false;

  Future<void> init({required bool authenticated}) async {
    try {
      await Firebase.initializeApp().timeout(const Duration(seconds: 8));
      _messaging = FirebaseMessaging.instance;
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      _firebaseReady = true;

      await _messaging!
          .requestPermission(alert: true, badge: true, sound: true)
          .timeout(const Duration(seconds: 8));

      await _messaging!.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      _listenForForegroundMessages();
      _listenForTokenRefresh();

      if (authenticated) {
        await registerDeviceToken();
      }
    } catch (e) {
      debugPrint('Notifications disabled: $e');
    }
  }

  Future<void> registerDeviceToken() async {
    if (!_firebaseReady) return;
    try {
      final messaging = _messaging;
      if (messaging == null) return;
      final token = await messaging.getToken().timeout(
        const Duration(seconds: 8),
      );
      if (token == null || token.isEmpty) return;
      await _notifications.registerToken(token: token, deviceType: _deviceType);
    } catch (e) {
      debugPrint('Could not register notification token: $e');
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    await _foregroundMessageSub?.cancel();
  }

  void _listenForForegroundMessages() {
    _foregroundMessageSub ??= FirebaseMessaging.onMessage.listen((message) {
      final title = _messageTitle(message);
      final body = _messageBody(message);
      incrementNotificationCount();
      _showSystemNotification(title: title, body: body);
    });
  }

  String _messageTitle(RemoteMessage message) {
    final notificationTitle = message.notification?.title;
    if (notificationTitle != null && notificationTitle.trim().isNotEmpty) {
      return notificationTitle;
    }

    final data = message.data;
    for (final key in const ['title', 'campaign_title', 'heading', 'subject']) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }

    final type = data['type']?.toString().toLowerCase() ?? '';
    if (type.contains('urgent') || type.contains('stock')) {
      return 'Urgent blood request';
    }
    if (type.contains('appointment')) return 'Appointment reminder';
    if (type.contains('campaign')) return 'NBTS campaign';
    return 'NBTS update';
  }

  String _messageBody(RemoteMessage message) {
    final notificationBody = message.notification?.body;
    if (notificationBody != null && notificationBody.trim().isNotEmpty) {
      return notificationBody;
    }

    final data = message.data;
    for (final key in const ['body', 'message', 'summary', 'content']) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }

    final bloodGroup = data['blood_group'] ?? data['blood_type'];
    final centerName = data['center_name'] ?? data['blood_center_name'];
    final parts = [bloodGroup, centerName]
        .whereType<Object>()
        .map((value) => value.toString().trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    if (parts.isNotEmpty) return parts.join(' - ');
    return '';
  }

  Future<void> _showSystemNotification({
    required String title,
    required String body,
  }) async {
    if (!Platform.isAndroid) return;
    try {
      await _nativeNotifications.invokeMethod('showNotification', {
        'title': title,
        'body': body,
      });
    } catch (e) {
      debugPrint('Could not show system notification: $e');
    }
  }

  void _listenForTokenRefresh() {
    final messaging = _messaging;
    if (messaging == null) return;
    _tokenRefreshSub ??= messaging.onTokenRefresh.listen((token) async {
      if (token.isEmpty) return;
      await _notifications.registerToken(token: token, deviceType: _deviceType);
    });
  }

  String get _deviceType {
    if (Platform.isIOS) return 'ios';
    return 'android';
  }
}

