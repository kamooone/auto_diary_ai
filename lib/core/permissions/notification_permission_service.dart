import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationPermissionService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> requestPermission() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@drawable/ic_notification'),
      iOS: DarwinInitializationSettings(),
    );

    await _plugin.initialize(settings);

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      await android?.requestNotificationsPermission();
    }
  }
}