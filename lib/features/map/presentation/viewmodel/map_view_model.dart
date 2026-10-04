import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../location/application/providers/location_providers.dart';
import '../../../location/domain/entities/location.dart';
import '../../../location/domain/entities/timeline_item.dart';

class MapState {
  final LatLng? currentLocation;
  final List<LatLng> history;
  final List<TimelineItem> timeline;
  final DateTime selectedDate;

  const MapState({
    this.currentLocation,
    this.history = const [],
    this.timeline = const [],
    required this.selectedDate,
  });

  MapState copyWith({
    LatLng? currentLocation,
    List<LatLng>? history,
    List<TimelineItem>? timeline,
    DateTime? selectedDate,
  }) {
    return MapState(
      currentLocation: currentLocation ?? this.currentLocation,
      history: history ?? this.history,
      timeline: timeline ?? this.timeline,
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
      selectedDate: date,
    );

    // 地名の取得に時間がかかるため、軌跡を表示した後にタイムラインを読み込む
    final timeline = await ref
        .read(getTimelineByDateUseCaseProvider)
        .execute(date);

    // 読み込み中に別の日付へ切り替えられた場合は反映しない
    if (state.selectedDate != date) {
      return;
    }

    state = state.copyWith(timeline: timeline);


    debugPrint(
      "${date.year}/${date.month}/${date.day} "
          "取得件数 = ${logs.length}",
    );
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