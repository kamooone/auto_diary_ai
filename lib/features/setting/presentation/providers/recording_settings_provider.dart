import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../location/application/providers/location_providers.dart';
import '../../../location/data/services/activity_recording_service.dart';

class RecordingSettingsState {
  /// 行動履歴の記録のオン・オフを切り替えられる端末かどうか
  final bool isSupported;

  /// 行動履歴を記録しているかどうか
  final bool isEnabled;

  /// アプリからホーム画面へのウィジェットの追加を求められるかどうか
  final bool isWidgetPinSupported;

  /// ホーム画面にウィジェットが置かれているかどうか
  final bool isWidgetPinned;

  const RecordingSettingsState({
    required this.isSupported,
    required this.isEnabled,
    required this.isWidgetPinSupported,
    required this.isWidgetPinned,
  });
}

/// 行動履歴の記録のオン・オフと、ホーム画面のウィジェットの状態
///
/// ウィジェットからも切り替えられるため、アプリに戻ってきたときは読み込み直すこと
final recordingSettingsProvider =
    AsyncNotifierProvider.autoDispose<
      RecordingSettingsNotifier,
      RecordingSettingsState
    >(RecordingSettingsNotifier.new);

class RecordingSettingsNotifier
    extends AutoDisposeAsyncNotifier<RecordingSettingsState> {
  @override
  Future<RecordingSettingsState> build() async {
    final dataSource = ref.watch(recordingStateDataSourceProvider);

    return RecordingSettingsState(
      isSupported: dataSource.isSupported,
      isEnabled: await dataSource.isEnabled(),
      isWidgetPinSupported: await dataSource.isWidgetPinSupported(),
      isWidgetPinned: await dataSource.isWidgetPinned(),
    );
  }

  /// 記録のオン・オフを切り替える
  /// オンにできなかった場合(位置情報が許可されなかった場合など)はfalseを返す
  ///
  /// [explainActivity]を渡すと、身体活動の許可をOSに尋ねる前(まだ許可しておらず、尋ねられるとき)に
  /// 呼ぶ。何のために使うのかの説明を出して、「次へ」ならtrue、「あとで」ならfalseを返す
  /// (falseのときは、OSのダイアログを出さない。記録は、身体活動なしでオンになる)
  Future<bool> setEnabled(
    bool enabled, {
    Future<bool> Function()? explainActivity,
    Future<bool> Function()? explainLocation,
  }) async {
    final dataSource = ref.read(recordingStateDataSourceProvider);

    if (enabled) {
      // 起動時に許可していなかった場合は、ここでもう一度求める
      // ([explainLocation]は、位置情報のOSのダイアログの前の説明。「あとで」なら許可を求めない)
      final granted = await ref
          .read(gpsLocationDataSourceProvider)
          .requestPermission(explain: explainLocation);

      if (!granted) return false;

      var askActivity = true;
      if (explainActivity != null && await canAskActivityPermission()) {
        askActivity = await explainActivity();
      }
      if (askActivity) await requestActivityPermission();
    }

    final result = await dataSource.setEnabled(enabled);

    ref.invalidateSelf();
    await future;

    return result == enabled;
  }

  /// ウィジェットをホーム画面に追加するよう求める
  /// 求められなかった場合はfalseを返す
  Future<bool> requestPinWidget() {
    return ref.read(recordingStateDataSourceProvider).requestPinWidget();
  }
}
