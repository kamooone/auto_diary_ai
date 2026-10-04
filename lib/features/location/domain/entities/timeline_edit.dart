import 'transport_mode.dart';

enum TimelineEditType { stay, move }

/// ユーザーがタイムラインに加えた修正
///
/// タイムラインは位置情報から毎回計算し直すため、修正は対象の時間帯とともに保存し、
/// 計算結果のうち時間帯が重なる滞在・移動に適用する。
class TimelineEdit {
  /// 保存前はnull
  final int? id;
  final TimelineEditType type;
  final DateTime start;
  final DateTime end;

  /// 滞在の場所名
  final String? placeName;

  /// 移動の手段
  final TransportMode? transport;

  /// 移動の説明(「〇〇さんの車で移動」など、ユーザーが自由に書いた文)
  final String? transportText;

  const TimelineEdit({
    this.id,
    required this.type,
    required this.start,
    required this.end,
    this.placeName,
    this.transport,
    this.transportText,
  });
}
