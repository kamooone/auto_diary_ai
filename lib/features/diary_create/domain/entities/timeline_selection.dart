import '../../../location/domain/entities/timeline_item.dart';

/// 行動履歴の選択画面の結果
class TimelineSelection {
  const TimelineSelection({required this.items, this.addressStays = const {}});

  /// 選んだ行動履歴(時系列の並び)
  final List<TimelineItem> items;

  /// 選んだ滞在のうち、住所(分からないときは座標)も、AIに送ると決めたもの
  final Set<TimelineItem> addressStays;
}
