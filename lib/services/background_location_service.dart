import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../features/map/data/models/location_log.dart';
import '../features/share/data/models/shared_post_model.dart';

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

  final dir = await getApplicationDocumentsDirectory();

  final isar = await Isar.open(
    [
      LocationLogSchema,
      SharedPostModelSchema,
    ],
    directory: dir.path,
  );

  Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 20,
    ),
  ).listen((position) async {
    debugPrint(
      "${position.latitude}, ${position.longitude}",
    );

    if (!position.latitude.isFinite ||
        !position.longitude.isFinite) {
      return;
    }

    final log = LocationLog()
      ..latitude = position.latitude
      ..longitude = position.longitude
      ..timestamp = DateTime.now();

    await isar.writeTxn(() async {
      await isar.locationLogs.put(log);
    });

    debugPrint("保存しました");
  });
}