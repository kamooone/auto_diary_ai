import 'package:isar/isar.dart';
import '../../features/location/data/datasources/gps_location_datasource.dart';
import '../../features/location/data/datasources/isar_location_datasource.dart';
import '../../features/location/data/datasources/recording_state_datasource.dart';
import '../../features/location/data/services/activity_recording_service.dart';
import '../../features/location/data/services/background_location_service.dart';
import '../../core/permissions/notification_permission_service.dart';

class AppInitializer {
  /// 許可は、位置情報 → 身体活動 → 通知の順に求める。
  /// 位置情報をまだ許可していない(求められる)ときは、先に[explain]で説明を見せる
  static Future<void> initialize(
    Isar isar, {
    required Future<void> Function() explain,
  }) async {
    final gps = GpsLocationDataSource();

    if (await gps.canRequestPermission()) {
      await explain();
    }

    // 位置情報許可
    final locationGranted = await gps.requestPermission();

    // 身体活動の許可(記録がオフでも、ほかの許可と同じく起動時に求める)
    await requestActivityPermission();

    // 通知許可(Android13以上)
    await NotificationPermissionService.requestPermission();

    await initializeBackgroundService();

    // 記録がオフの間は開始しない(オン・オフを切り替えられる端末では、最初はオフ)
    final recordingState = RecordingStateDataSource();

    if (!await recordingState.isEnabled()) {
      // オン・オフを切り替えられるようにする前から動いていた記録が残っていれば止める
      await recordingState.setEnabled(false);

      // オフにする前の行動の記録が残っていれば取り込む
      await importRecordedActivities(isar);
      return;
    }

    // 位置情報が許可されている場合のみ記録を開始する
    if (locationGranted) {
      await startLocationRecording(
        gps: gps,
        local: IsarLocationDataSource(isar),
      );
    }

    // 行動認識(徒歩・自転車・乗り物など)の記録を開始する
    await startActivityRecording(isar);
  }
}