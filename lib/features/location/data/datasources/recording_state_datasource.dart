import 'dart:io';
import 'package:flutter/services.dart';

/// 行動履歴(位置情報と行動認識)の記録のオン・オフ
///
/// Android: ホーム画面のウィジェットからも切り替えられるよう、状態はネイティブ側が持つ
/// それ以外: 切り替えにはまだ対応しておらず、常に記録する
class RecordingStateDataSource {
  static const _channel = MethodChannel('auto_diary_ai/recording');

  /// オン・オフを切り替えられるかどうか
  bool get isSupported => Platform.isAndroid;

  Future<bool> isEnabled() async {
    if (!isSupported) return true;

    return await _channel.invokeMethod<bool>('isEnabled') ?? false;
  }

  /// 記録のオン・オフを切り替え、切り替え後の状態を返す
  /// (位置情報が許可されていないなど、開始できなかった場合はオフのままになる)
  Future<bool> setEnabled(bool enabled) async {
    if (!isSupported) return true;

    return await _channel.invokeMethod<bool>(
          'setEnabled',
          {'enabled': enabled},
        ) ??
        false;
  }

  /// オン・オフを切り替えた時刻の一覧(古い順)
  Future<List<({bool enabled, DateTime timestamp})>> getHistory() async {
    if (!isSupported) return [];

    final records =
        await _channel.invokeListMethod<Map<Object?, Object?>>('history');

    return [
      for (final record in records ?? const <Map<Object?, Object?>>[])
        (
          enabled: record['enabled'] as bool,
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            (record['timestamp'] as num).toInt(),
          ),
        ),
    ];
  }

  /// ウィジェットをホーム画面に置くかどうかを、まだ尋ねていないかどうか
  /// 尋ねるのは一度だけなので、呼び出すと尋ねたものとして記録される
  Future<bool> consumeWidgetPrompt() async {
    if (!isSupported) return false;

    return await _channel.invokeMethod<bool>('consumeWidgetPrompt') ?? false;
  }

  /// アプリからウィジェットの追加を求められるかどうか
  Future<bool> isWidgetPinSupported() async {
    if (!isSupported) return false;

    return await _channel.invokeMethod<bool>('isWidgetPinSupported') ?? false;
  }

  /// ホーム画面にウィジェットが置かれているかどうか
  Future<bool> isWidgetPinned() async {
    if (!isSupported) return false;

    return await _channel.invokeMethod<bool>('isWidgetPinned') ?? false;
  }

  /// ウィジェットをホーム画面に追加するよう求める(追加するかどうかはユーザーが確認する)
  Future<bool> requestPinWidget() async {
    if (!isSupported) return false;

    return await _channel.invokeMethod<bool>('requestPinWidget') ?? false;
  }
}
