import '../entities/location.dart';
import '../entities/recording_pause.dart';
import '../entities/timeline_item.dart';
import '../repositories/activity_repository.dart';
import '../repositories/location_repository.dart';
import '../repositories/place_name_repository.dart';
import '../repositories/place_search_repository.dart';
import '../repositories/recording_pause_repository.dart';
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

  final RecordingPauseRepository recordingPauseRepository;

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
    required this.recordingPauseRepository,
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
    final nextDay = DateTime(day.year, day.month, day.day + 1);

    // 日をまたいだ滞在が分かるよう、その日の前後の位置も使う
    final previous = _within(
      await repository.getLastLocationBefore(day),
      from: day.subtract(_maxCarryOver),
      to: day,
    );
    final next = _within(
      await repository.getFirstLocationFrom(nextDay),
      from: nextDay,
      to: nextDay.add(_maxCarryOver),
    );

    // 記録をオフにしていた期間(その間は、どこにいたか分からないものとして扱う)
    final pauses = [
      for (final pause in await recordingPauseRepository.getPauses(
        previous?.timestamp ?? day,
        next?.timestamp ?? nextDay,
      ))
        if (!_isBrief(pause)) pause,
    ];

    // 過去の日は内容が変わらないため、計算済みの結果があればそれを使う
    final isPast = day.isBefore(today);

    // 計算のもとになる位置情報や、記録をオフにしていた期間が変わったら、保存した結果は使わない
    final signature = [
      locations.length,
      previous?.timestamp.millisecondsSinceEpoch,
      next?.timestamp.millisecondsSinceEpoch,
      for (final pause in pauses)
        "${pause.start.millisecondsSinceEpoch}-"
            "${pause.end?.millisecondsSinceEpoch}",
    ].join("|");

    var items = isPast
        ? await timelineSnapshotRepository.find(day, signature: signature)
        : null;

    if (items == null) {
      final computed = await _compute(
        _build(
          locations,
          day: day,
          nextDay: nextDay,
          previous: previous,
          next: next,
          pauses: pauses,
          // 今日の場合は、今の時刻までを対象にする
          now: day == today ? now : null,
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
          signature: signature,
        );
      }
    }

    // 記録をオフにしていた時間帯も、その日の終わり(今日の場合は今の時刻)まで表示する
    final recordingOffs = _recordingOffs(
      pauses,
      from: day,
      to: day == today ? now : nextDay.subtract(const Duration(seconds: 1)),
    );

    if (items.isEmpty) return recordingOffs;

    // ユーザーが修正した場所名・移動手段を当てはめる
    final edits = await timelineEditRepository.findOverlapping(
      items.first.start,
      items.last.end,
    );

    // 並べ替えても、同じ時刻に始まるものの順番は変わらないようにする
    final all = [..._applier.apply(items, edits), ...recordingOffs];
    final order = {for (final (index, item) in all.indexed) item: index};

    return all
      ..sort((a, b) {
        final byStart = a.start.compareTo(b.start);
        return byStart != 0 ? byStart : order[a]!.compareTo(order[b]!);
      });
  }

  /// 記録をオフにしていた期間のうち、[from]から[to]までに重なる部分
  List<TimelineItem> _recordingOffs(
    List<RecordingPause> pauses, {
    required DateTime from,
    required DateTime to,
  }) {
    final items = <TimelineItem>[];

    for (final pause in pauses) {
      final start = pause.start.isAfter(from) ? pause.start : from;

      final resumedAt = pause.end;
      final end = resumedAt != null && resumedAt.isBefore(to) ? resumedAt : to;

      if (end.isAfter(start)) {
        items.add(RecordingOff(start: start, end: end));
      }
    }

    return items;
  }

  // 前後の日の位置がこれより離れた時刻のものなら、その間の居場所は分からないものとする
  static const _maxCarryOver = Duration(hours: 72);

  // これより短いオフは、記録が続いていたものとして扱う
  // (オフにしてすぐオンに戻しただけで、同じ場所の滞在が2つに分かれないようにする)
  static const _minPauseDuration = Duration(minutes: 10);

  bool _isBrief(RecordingPause pause) {
    final end = pause.end;
    return end != null && end.difference(pause.start) < _minPauseDuration;
  }

  Location? _within(
    Location? location, {
    required DateTime from,
    required DateTime to,
  }) {
    if (location == null) return null;

    final time = location.timestamp;
    return time.isBefore(from) || time.isAfter(to) ? null : location;
  }

  /// 位置情報を滞在と移動に要約する
  ///
  /// 記録をオフにしていた間は、位置情報が途切れていても同じ場所にいたとはみなせない。
  /// そのため、その日を「記録していた時間帯」に分け、時間帯ごとに要約する
  ///
  /// [now]は今日のタイムラインの場合だけ渡す
  List<TimelineItem> _build(
    List<Location> locations, {
    required DateTime day,
    required DateTime nextDay,
    required Location? previous,
    required Location? next,
    required List<RecordingPause> pauses,
    required DateTime? now,
  }) {
    final limit = now ?? nextDay;

    // その日のうち、記録していた時間帯
    final windows = <({DateTime start, DateTime end})>[];
    var cursor = day;

    for (final pause in pauses) {
      if (!pause.start.isBefore(limit)) break;

      if (pause.start.isAfter(cursor)) {
        windows.add((start: cursor, end: pause.start));
      }

      // 今もオフのままの場合は、それ以降に記録していた時間帯はない
      final resumedAt = pause.end ?? limit;
      if (resumedAt.isAfter(cursor)) cursor = resumedAt;
    }

    if (cursor.isBefore(limit)) {
      windows.add((start: cursor, end: limit));
    }

    // 前後の日の位置との間でオフにしていた場合は、日をまたいだ滞在として扱わない
    final carriesFromPrevious = previous != null &&
        !pauses.any((pause) => pause.overlaps(previous.timestamp, day));
    final carriesToNext = next != null &&
        !pauses.any((pause) => pause.overlaps(nextDay, next.timestamp));

    final items = <TimelineItem>[];

    for (final window in windows) {
      final isFirst = window.start == day;
      final isLast = window.end == limit;

      items.addAll(
        _builder.build(
          [
            for (final location in locations)
              if (!location.timestamp.isBefore(window.start) &&
                  location.timestamp.isBefore(window.end))
                location,
          ],
          dayStart: day,
          previous: isFirst && carriesFromPrevious ? previous : null,
          // その日の終わり(23:59:59)
          dayEnd: nextDay.subtract(const Duration(seconds: 1)),
          next: isLast && now == null && carriesToNext ? next : null,
          // 最後にいた場所に、オフにした時刻までとどまっていたものとして扱う
          // (今日の最後の時間帯は、今もとどまっているものとして扱う)
          until: isLast ? now : window.end,
        ),
      );
    }

    return items;
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
        case RecordingOff():
          items.add(item);
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
