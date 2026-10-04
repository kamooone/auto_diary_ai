import 'package:flutter/services.dart';
import '../models/location_log.dart';

/// iOSのネイティブ側(AppDelegate.swiftのLocationRecorder)で行う位置情報の記録
///
/// iOSはアプリを完全終了した後もOSがアプリを再起動して位置を通知するが、
/// その時点ではDartが動いているとは限らない。ネイティブ側が溜めた位置情報を
/// ここから取り出してIsarへ保存する。
class IosLocationRecorderDataSource {
  static const _channel = MethodChannel('auto_diary_ai/location_recorder');

  /// 記録を開始する(位置情報が許可されている状態で呼び出すこと)
  Future<void> start() {
    return _channel.invokeMethod<void>('start');
  }

  /// ネイティブ側に溜まっている位置情報を取り出す
  /// 保存が完了したら[confirmDrain]を呼ぶこと
  Future<List<LocationLog>> drain() async {
    final records = await _channel.invokeListMethod<Map<Object?, Object?>>(
      'drain',
    );

    return [
      for (final record in records ?? const <Map<Object?, Object?>>[])
        LocationLog()
          ..latitude = (record['latitude'] as num).toDouble()
          ..longitude = (record['longitude'] as num).toDouble()
          ..timestamp = DateTime.fromMillisecondsSinceEpoch(
            (record['timestamp'] as num).toInt(),
          ),
    ];
  }

  /// 取り出した位置情報をネイティブ側から削除する
  Future<void> confirmDrain() {
    return _channel.invokeMethod<void>('confirmDrain');
  }
}
