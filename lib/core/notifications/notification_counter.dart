import 'package:flutter/foundation.dart';

final notificationCount = ValueNotifier<int>(0);

void setNotificationCount(int value) {
  notificationCount.value = value < 0 ? 0 : value;
}

void incrementNotificationCount() {
  notificationCount.value = notificationCount.value + 1;
}

void clearNotificationCount() {
  notificationCount.value = 0;
}
