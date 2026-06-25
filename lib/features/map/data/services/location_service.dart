import 'dart:async';
import 'dart:developer' as developer;
import 'package:geolocator/geolocator.dart';
import 'package:auto_diary_ai/common/constants/map_constants.dart';
import 'package:auto_diary_ai/features/map/data/repositories/location_repository.dart';


/// 位置情報サービス
///
/// 役割
/// ・GPSから現在地を取得
/// ・取得した位置をStreamでUIへ配信
/// ・位置履歴をDB(Isar)へ保存
/// ・保存済み履歴を読み込み
///
/// 構造
/// Geolocator → LocationService → UI
///                        ↓
///                       Isar(DB)
class LocationService {

  /// 位置情報Repository
  /// DB操作を担当
  final LocationRepository repository;

  /// 現在地を配信するStreamController
  /// broadcastにより複数画面から同時購読可能
  final StreamController<Position> _locationController = StreamController.broadcast();

  /// RepositoryをDIで受け取る
  LocationService(this.repository);

  /// GPS購読
  StreamSubscription<Position>? _positionStream;

  /// UIが購読する位置Stream
  Stream<Position> get locationStream => _locationController.stream;


  /// DBから保存済み位置履歴を読み込み
  Future<void> loadLocations() async {

    final logs = await repository.getLocations();

    developer.log(
      "DB records: ${logs.length}",
      name: "LocationService",
    );

    for (final log in logs) {
      developer.log(
        "DB: ${log.latitude}, ${log.longitude}, ${log.timestamp}",
        name: "LocationService",
      );
    }

  }


  /// GPS取得開始
  ///
  /// 処理
  /// 1 GPS有効確認
  /// 2 権限確認
  /// 3 GPS Stream開始
  /// 4 UIへ位置配信
  /// 5 DB保存
  Future<void> start() async {

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      developer.log("Location service disabled");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      developer.log("Location permission denied forever");
      return;
    }

    /// GPS設定
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,

      /// 指定距離移動したら更新
      distanceFilter: MapConstants.locationDistanceFilterMeters,
    );

    /// GPSリアルタイム取得
    _positionStream = Geolocator
        .getPositionStream(locationSettings: locationSettings)

        /// 位置更新時処理
        .listen((position) async {
          developer.log(
            "Location received: ${position.latitude}, ${position.longitude}",
            name: "LocationService",
          );

          /// UIへ位置配信
          _locationController.add(position);

          /// DB保存
          await repository.saveLocation(
            position.latitude,
            position.longitude,
          );
        });
  }


  /// Service終了処理
  /// GPS購読停止 + Streamクローズ
  void dispose() {
    _positionStream?.cancel();
    _locationController.close();
  }
}