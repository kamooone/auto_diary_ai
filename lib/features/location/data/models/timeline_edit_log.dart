import 'package:isar/isar.dart';

part 'timeline_edit_log.g.dart';

/// ユーザーがタイムラインに加えた修正
@collection
class TimelineEditLog {
  Id id = Isar.autoIncrement;

  /// 修正の対象(stay / move)
  late String type;

  /// 修正した滞在・移動の時間帯
  late DateTime start;
  late DateTime end;

  /// 滞在の場所名
  String? placeName;

  /// 移動手段(TransportModeの名前)
  String? transport;

  /// 移動の説明(ユーザーが自由に書いた文)
  String? transportText;
}
