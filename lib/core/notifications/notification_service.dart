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

      await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      ).timeout(const Duration(seconds: 8));

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
      await _notifications.registerToken(
        token: token,
        deviceType: _deviceType,
      );
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
      final notification = message.notification;
      final title = notification?.title ?? message.data['title']?.toString();
      final body = notification?.body ?? message.data['body']?.toString();
      incrementNotificationCount();
      _showSystemNotification(
        title: title == null || title.isEmpty ? 'NBTS update' : title,
        body: body ?? '',
      );
    });
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
      await _notifications.registerToken(
        token: token,
        deviceType: _deviceType,
      );
    });
  }

  String get _deviceType {
    if (Platform.isIOS) return 'ios';
    return 'android';
  }
}

