import 'package:isar_community/isar.dart';
import '../../features/location/data/datasources/gps_location_datasource.dart';
import '../../features/location/data/datasources/isar_location_datasource.dart';
import '../../features/location/data/datasources/recording_state_datasource.dart';
import '../../features/location/data/services/activity_recording_service.dart';
import '../../features/location/data/services/background_location_service.dart';

class AppInitializer {
  /// 許可のダイアログは、ここでは出さない(許可済みのときだけ、記録を始める)
  static Future<void> initialize(Isar isar) async {
    final gps = GpsLocationDataSource();
    final locationGranted = await gps.hasPermission();

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