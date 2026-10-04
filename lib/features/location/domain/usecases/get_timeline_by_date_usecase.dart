import '../entities/timeline_item.dart';
import '../repositories/location_repository.dart';
import '../repositories/place_name_repository.dart';
import '../services/timeline_builder.dart';

class GetTimelineByDateUseCase {

  final LocationRepository repository;

  final PlaceNameRepository placeNameRepository;

  final TimelineBuilder _builder = TimelineBuilder();

  GetTimelineByDateUseCase(
      this.repository,
      this.placeNameRepository,
      );

  /// 指定した日の行動を「滞在」と「移動」に要約して取得
  Future<List<TimelineItem>> execute(
      DateTime date,
      ) async {
    final locations = await repository.getLocationsByDate(date);

    // 今日の場合は、最後にいた場所に今もとどまっているものとして扱う
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;

    final items = _builder.build(
      locations,
      until: isToday ? now : null,
    );

    final result = <TimelineItem>[];
    for (final item in items) {
      if (item is Stay) {
        final placeName = await placeNameRepository.getPlaceName(
          item.latitude,
          item.longitude,
        );
        result.add(item.copyWith(placeName: placeName));
      } else {
        result.add(item);
      }
    }

    return result;
  }
}
