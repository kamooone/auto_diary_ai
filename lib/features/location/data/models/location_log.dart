/*
* flutter pub run build_runner buildを実行して.g.dartファイルを作成する必要
*/

import 'package:isar/isar.dart';

/// build_runner によって生成されるコードを結合する
/// Isarはコード生成でSchemaやQueryを作る
part 'location_log.g.dart';


/// Isarのコレクション（テーブル）として登録する
/// このクラスがDBに保存されるデータ構造になる
@collection
class LocationLog {

  /// 主キー（Primary Key）
  /// Isar.autoIncrement により保存時に自動採番される
  Id id = Isar.autoIncrement;

  /// 緯度（Latitude）
  /// GPSから取得した位置情報
  late double latitude;

  /// 経度（Longitude）
  /// GPSから取得した位置情報
  late double longitude;

  /// 位置情報を取得した時刻
  /// 保存時に DateTime.now() がセットされる
  late DateTime timestamp;
}