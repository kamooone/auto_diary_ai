import '../entities/timeline_item.dart';
import '../repositories/activity_repository.dart';
import '../repositories/location_repository.dart';
import '../repositories/place_name_repository.dart';
import '../repositories/place_search_repository.dart';
import '../repositories/timeline_edit_repository.dart';
import '../services/place_estimator.dart';
import '../services/timeline_builder.dart';
import '../services/timeline_edit_applier.dart';
import '../services/transport_estimator.dart';

class GetTimelineByDateUseCase {

  final LocationRepository repository;

  final PlaceNameRepository placeNameRepository;

  final TimelineEditRepository timelineEditRepository;

  final PlaceSearchRepository placeSearchRepository;

  final ActivityRepository activityRepository;

  final TimelineBuilder _builder = TimelineBuilder();

  final TransportEstimator _transportEstimator = TransportEstimator();

  final PlaceEstimator _estimator = PlaceEstimator();

  final TimelineEditApplier _applier = TimelineEditApplier();

  GetTimelineByDateUseCase({
    required this.repository,
    required this.placeNameRepository,
    required this.timelineEditRepository,
    required this.placeSearchRepository,
    required this.activityRepository,
  });

  /// 指定した日の行動を「滞在」と「移動」に要約して取得
  ///
  /// [estimatePlaces]がtrueの場合、ユーザーが場所を確認していない滞在に、
  /// 周辺の最も近い施設を訪れた場所として当てはめる
  Future<List<TimelineItem>> execute(
      DateTime date, {
      bool estimatePlaces = true,
      }) async {
    final locations = await repository.getLocationsByDate(date);

    // 今日の場合は、最後にいた場所に今もとどまっているものとして扱う
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;

    final built = _builder.build(
      locations,
      until: isToday ? now : null,
    );
    if (built.isEmpty) return [];

    // OSの行動認識が使える区間は、速度からの推定よりそちらを優先する
    final activities = await activityRepository.getActivities(
      built.first.start,
      built.last.end,
    );
    final estimated = [
      for (final item in built)
        if (item is Move)
          item.copyWith(
            transport: _transportEstimator.estimate(item, activities),
          )
        else
          item,
    ];

    // ユーザーが修正した場所名・移動手段を当てはめる
    final edits = await timelineEditRepository.findOverlapping(
      built.first.start,
      built.last.end,
    );
    final items = _applier.apply(estimated, edits);

    final result = <TimelineItem>[];
    for (final item in items) {
      // 場所名が修正されていない滞在だけ、座標から地名を取得する
      if (item is Stay && item.placeName == null) {
        final placeName = await placeNameRepository.getPlaceName(
          item.latitude,
          item.longitude,
        );
        result.add(item.copyWith(placeName: placeName));
      } else {
        result.add(item);
      }
    }

    if (!estimatePlaces) return result;

    return _estimatePlaces(result);
  }

  Future<List<TimelineItem>> _estimatePlaces(List<TimelineItem> items) async {
    final stays = [
      for (final item in items)
        if (item is Stay && !item.isPlaceNameEdited) item,
    ];
    if (stays.isEmpty) return items;

    final candidates = await placeSearchRepository.findNearby([
      for (final stay in stays)
        (latitude: stay.latitude, longitude: stay.longitude),
    ]);

    final estimated = <Stay, String>{};
    for (var i = 0; i < stays.length; i++) {
      final place = _estimator.estimate(candidates[i]);
      if (place != null) {
        estimated[stays[i]] = place.name;
      }
    }

    return [
      for (final item in items)
        if (item is Stay && estimated.containsKey(item))
          item.copyWith(estimatedPlaceName: estimated[item])
        else
          item,
    ];
  }
}
