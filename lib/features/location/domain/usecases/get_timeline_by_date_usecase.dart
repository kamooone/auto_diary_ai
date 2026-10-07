import '../entities/timeline_item.dart';
import '../repositories/activity_repository.dart';
import '../repositories/location_repository.dart';
import '../repositories/place_name_repository.dart';
import '../repositories/place_search_repository.dart';
import '../repositories/timeline_edit_repository.dart';
import '../repositories/timeline_snapshot_repository.dart';
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

  final TimelineSnapshotRepository timelineSnapshotRepository;

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
    required this.timelineSnapshotRepository,
  });

  /// 指定した日の行動を「滞在」と「移動」に要約して取得
  ///
  /// [estimatePlaces]がtrueの場合、周辺の最も近い施設を訪れた場所として当てはめる
  /// (ユーザーが場所を確認していない滞在に表示される)
  Future<List<TimelineItem>> execute(
      DateTime date, {
      bool estimatePlaces = true,
      }) async {
    final locations = await repository.getLocationsByDate(date);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);

    // 過去の日は内容が変わらないため、計算済みの結果があればそれを使う
    final isPast = day.isBefore(today);

    var items = isPast
        ? await timelineSnapshotRepository.find(
            day,
            locationCount: locations.length,
          )
        : null;

    if (items == null) {
      final computed = await _compute(
        locations.isEmpty
            ? const []
            : _builder.build(
                locations,
                // 今日の場合は、最後にいた場所に今もとどまっているものとして扱う
                until: day == today ? now : null,
              ),
        estimatePlaces: estimatePlaces,
      );
      items = computed.items;

      // 地名や施設をすべて取得できた場合だけ保存する
      // (通信できなかった結果を保存すると、次回以降も地名が出ないままになるため)
      if (isPast && computed.isComplete) {
        await timelineSnapshotRepository.save(
          day,
          items,
          locationCount: locations.length,
        );
      }
    }

    if (items.isEmpty) return [];

    // ユーザーが修正した場所名・移動手段を当てはめる
    final edits = await timelineEditRepository.findOverlapping(
      items.first.start,
      items.last.end,
    );

    return _applier.apply(items, edits);
  }

  /// 滞在と移動に、移動手段・地名・訪れた施設を当てはめる
  Future<({List<TimelineItem> items, bool isComplete})> _compute(
    List<TimelineItem> built, {
    required bool estimatePlaces,
  }) async {
    if (built.isEmpty) return (items: built, isComplete: true);

    var isComplete = true;

    // OSの行動認識が使える区間は、速度からの推定よりそちらを優先する
    final activities = await activityRepository.getActivities(
      built.first.start,
      built.last.end,
    );

    final items = <TimelineItem>[];
    for (final item in built) {
      switch (item) {
        case Move():
          items.add(
            item.copyWith(
              transport: _transportEstimator.estimate(item, activities),
            ),
          );
        case Stay():
          // 座標から地名を取得する
          final placeName = await placeNameRepository.getPlaceName(
            item.latitude,
            item.longitude,
          );
          if (placeName == null) isComplete = false;

          items.add(item.copyWith(placeName: placeName));
      }
    }

    if (!estimatePlaces) return (items: items, isComplete: false);

    try {
      return (items: await _estimatePlaces(items), isComplete: isComplete);
    } catch (e) {
      // 施設を検索できなかった場合は、地名だけで表示する
      return (items: items, isComplete: false);
    }
  }

  Future<List<TimelineItem>> _estimatePlaces(List<TimelineItem> items) async {
    final stays = items.whereType<Stay>().toList();
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
