import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import '../datasources/gps_location_datasource.dart';
import '../datasources/ios_location_recorder_datasource.dart';
import '../datasources/isar_location_datasource.dart';
import '../../../../core/database/background_isar.dart';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      // 端末起動時はアプリが画面に出ていないため、位置情報が「常に許可」でないと
      // Android14以上でサービスを開始できない。記録はアプリ起動時に開始する
      autoStartOnBoot: false,
      isForegroundMode: true,
      foregroundServiceNotificationId: 100,
      // Android14以上はフォアグラウンドサービスの種別指定が必須
      foregroundServiceTypes: [AndroidForegroundType.location],
      initialNotificationTitle: 'Auto Diary AI',
      initialNotificationContent: '位置情報を記録しています',
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
    ),
  );
}

// Android・iOS以外でメインIsolateが行っている記録
StreamSubscription<Position>? _recordingSubscription;

final _iosRecorder = IosLocationRecorderDataSource();

// 取り込みが同時に走らないよう、前の取り込みの完了を待つ
Future<void> _importing = Future.value();

/// 位置情報の記録を開始する(すでに開始済みの場合は何もしない)
///
/// Android: フォアグラウンドサービス(別Isolate)で記録し、アプリ終了後も継続する
/// iOS: ネイティブ側で記録する。アプリを完全終了した後も、OSが位置の変化を
///      検知してアプリを再起動し、記録を再開する
///
/// 位置情報が許可されている状態で呼び出すこと
Future<void> startLocationRecording({
  required GpsLocationDataSource gps,
  required IsarLocationDataSource local,
}) async {
  if (Platform.isAndroid) {
    final service = FlutterBackgroundService();

    if (!await service.isRunning()) {
      await service.startService();
    }
    return;
  }

  if (Platform.isIOS) {
    try {
      await _iosRecorder.start();
    } catch (e) {
      debugPrint('位置情報の記録を開始できませんでした: $e');
    }

    await importRecordedLocations(local);
    return;
  }

  _recordingSubscription ??= gps.getPositionStream().listen(
    (position) async {
      await local.save(
        position.latitude,
        position.longitude,
      );
    },
    onError: (Object error) {
      debugPrint('位置情報の記録に失敗しました: $error');
    },
  );
}

/// iOSのネイティブ側が溜めた位置情報をIsarへ取り込む(iOS以外では何もしない)
Future<void> importRecordedLocations(IsarLocationDataSource local) {
  if (!Platform.isIOS) {
    return Future.value();
  }

  return _importing = _importing.then((_) async {
    try {
      final logs = await _iosRecorder.drain();

      if (logs.isEmpty) {
        return;
      }

      await local.saveAll(logs);
      await _iosRecorder.confirmDrain();
    } catch (e) {
      debugPrint('位置情報の取り込みに失敗しました: $e');
    }
  });
}

@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  final isar = await openBackgroundIsar();

  final gpsDataSource = GpsLocationDataSource();
  final locationDataSource = IsarLocationDataSource(isar);

  gpsDataSource.getPositionStream().listen(
    (position) async {
      await locationDataSource.save(
        position.latitude,
        position.longitude,
      );

      debugPrint(
        '保存しました: ${position.latitude}, ${position.longitude}',
      );
    },
    onError: (Object error) {
      debugPrint('位置情報の記録に失敗しました: $error');
    },
  );
}