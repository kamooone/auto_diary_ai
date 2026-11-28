import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../common/constants/location_constants.dart';

class GpsLocationDataSource {

  /// すでに許可されているか(許可のダイアログは出さない)
  Future<bool> hasPermission() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return false;

      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (_) {
      return false;
    }
  }

  /// 許可を求める。まだ許可していなければ、OSのダイアログを出し、答えるまで待つ
  ///
  /// [explain]を渡すと、OSのダイアログを出す前(まだ許可しておらず、尋ねられるとき)に呼ぶ。
  /// 何のために使うのかの説明を出して、同意なら true、「あとで」なら false を返す
  /// (false のときは、OSのダイアログを出さず、許可されていない扱いにする)
  Future<bool> requestPermission({Future<bool> Function()? explain}) async {

    final enabled =
    await Geolocator.isLocationServiceEnabled();

    if (!enabled) {
      return false;
    }

    var permission =
    await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      if (explain != null && !await explain()) return false;

      permission =
      await Geolocator.requestPermission();
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: LocationConstants.distanceFilterMeters,
      ),
    ).where((position) {
      // 精度の悪い位置は、室内などで実際とは大きくずれていることがあるため使わない
      final ok =
          position.latitude.isFinite &&
              position.longitude.isFinite &&
              position.accuracy <= LocationConstants.maxAccuracyMeters;

      if (!ok) {
        debugPrint(
          "破棄: ${position.latitude}, ${position.longitude} "
              "(精度 ${position.accuracy}m)",
        );
      }

      return ok;
    });
  }

}