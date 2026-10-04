import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../location/application/providers/location_providers.dart';
import '../../../location/domain/entities/location.dart';
import '../../../location/domain/entities/place_candidate.dart';
import '../../../location/domain/entities/timeline_item.dart';
import '../../../location/domain/entities/transport_mode.dart';

class MapState {
  final LatLng? currentLocation;
  final List<LatLng> history;
  final List<TimelineItem> timeline;

  /// 滞在の開始時刻ごとの、周辺の施設の候補
  final Map<DateTime, List<PlaceCandidate>> placeCandidates;

  final DateTime selectedDate;

  const MapState({
    this.currentLocation,
    this.history = const [],
    this.timeline = const [],
    this.placeCandidates = const {},
    required this.selectedDate,
  });

  MapState copyWith({
    LatLng? currentLocation,
    List<LatLng>? history,
    List<TimelineItem>? timeline,
    Map<DateTime, List<PlaceCandidate>>? placeCandidates,
    DateTime? selectedDate,
  }) {
    return MapState(
      currentLocation: currentLocation ?? this.currentLocation,
      history: history ?? this.history,
      timeline: timeline ?? this.timeline,
      placeCandidates: placeCandidates ?? this.placeCandidates,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }
}

class MapViewModel extends Notifier<MapState> {
  StreamSubscription<Location>? _subscription;

  @override
  MapState build() {
    ref.onDispose(() async {
      await stop();
    });

    return MapState(
      selectedDate: DateTime.now(),
    );
  }

  Future<void> initialize() async {
    await loadTimeline(state.selectedDate);
  }

  Future<void> loadTimeline(DateTime date) async {

    final logs = await ref
        .read(getLocationsByDateUseCaseProvider)
        .execute(date);


    final history = logs
        .map((e) => LatLng(
      e.latitude,
      e.longitude,
    ))
        .toList();

    state = state.copyWith(
      history: history,
      timeline: const [],
      placeCandidates: const {},
      selectedDate: date,
    );

    // 地名の取得に時間がかかるため、軌跡を表示した後にタイムラインを読み込む
    await _reloadTimeline();


    debugPrint(
      "${date.year}/${date.month}/${date.day} "
          "取得件数 = ${logs.length}",
    );
  }

  Future<void> _reloadTimeline() async {
    final date = state.selectedDate;

    final getTimeline = ref.read(getTimelineByDateUseCaseProvider);

    // 施設の検索は時間がかかることがあるため、先に住所だけのタイムラインを表示する
    final quick = await getTimeline.execute(date, estimatePlaces: false);

    // 読み込み中に別の日付へ切り替えられた場合は反映しない
    if (state.selectedDate != date) {
      return;
    }

    // すでに施設を当てはめて表示している場合は、住所だけの表示に戻さない
    if (state.timeline.isEmpty) {
      state = state.copyWith(timeline: quick);
    }

    // 未確認の滞在に、最も近い施設を当てはめる
    final timeline = await getTimeline.execute(date);

    if (state.selectedDate != date) {
      return;
    }

    state = state.copyWith(timeline: timeline);

    // 編集時に選べるよう、施設の候補も読み込む(検索結果は保存済みのものを再利用する)
    final stays = timeline.whereType<Stay>().toList();

    final candidates = await ref
        .read(getPlaceCandidatesUseCaseProvider)
        .execute(stays);

    if (state.selectedDate != date) {
      return;
    }

    state = state.copyWith(
      placeCandidates: {
        for (var i = 0; i < stays.length; i++) stays[i].start: candidates[i],
      },
    );
  }

  /// 滞在の場所名を修正する(nullの場合は自動で取得した場所名に戻す)
  Future<void> updateStayPlaceName(Stay stay, String? placeName) async {
    await ref
        .read(updateStayPlaceNameUseCaseProvider)
        .execute(stay, placeName);

    await _reloadTimeline();
  }

  /// 移動手段と移動の説明を修正する(どちらもnullの場合は自動推定に戻す)
  Future<void> updateMoveTransport(
    Move move, {
    TransportMode? transport,
    String? text,
  }) async {
    await ref
        .read(updateMoveTransportUseCaseProvider)
        .execute(move, transport: transport, text: text);

    await _reloadTimeline();
  }

  Future<void> start() async {
    _subscription = ref
        .read(startLocationTrackingUseCaseProvider)
        .execute()
        .listen((location) {

      state = state.copyWith(
        currentLocation: LatLng(
          location.latitude,
          location.longitude,
        ),
      );
    });
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}