import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../application/providers/location_providers.dart';
import '../../domain/entities/location.dart';

class MapState {
  final LatLng? currentLocation;
  final List<LatLng> history;
  final DateTime selectedDate;

  const MapState({
    this.currentLocation,
    this.history = const [],
    required this.selectedDate,
  });

  MapState copyWith({
    LatLng? currentLocation,
    List<LatLng>? history,
    DateTime? selectedDate,
  }) {
    return MapState(
      currentLocation: currentLocation ?? this.currentLocation,
      history: history ?? this.history,
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
      selectedDate: date,
    );


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

  Future<void> debugPrintAllLocations() async {
    final logs = await ref.read(getLocationsUseCaseProvider).execute();

    debugPrint("========== 保存されている位置情報 ==========");
    debugPrint("件数: ${logs.length}");

    for (final log in logs) {
      debugPrint(
        "${log.timestamp}  "
            "${log.latitude}, ${log.longitude}",
      );
    }

    debugPrint("==========================================");
  }
}