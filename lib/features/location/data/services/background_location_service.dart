import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter/widgets.dart';
import '../datasources/gps_location_datasource.dart';
import '../datasources/isar_location_datasource.dart';
import '../../../../core/database/background_isar.dart';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      foregroundServiceNotificationId: 100,
      initialNotificationTitle: 'Auto Diary AI',
      initialNotificationContent: '位置情報を記録しています',
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
    ),
  );
}

@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  final isar = await openBackgroundIsar();

  final gpsDataSource = GpsLocationDataSource();
  final locationDataSource = IsarLocationDataSource(isar);

  gpsDataSource.getPositionStream().listen((position) async {
    await locationDataSource.save(
      position.latitude,
      position.longitude,
    );

    debugPrint(
      '保存しました: ${position.latitude}, ${position.longitude}',
    );
  });
}