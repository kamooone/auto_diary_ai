import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../application/providers/location_providers.dart';
import '../../domain/entities/location.dart';

class MapState {
  final LatLng? currentLocation;
  final List<LatLng> history;

  const MapState({
    this.currentLocation,
    this.history = const [],
  });

  MapState copyWith({
    LatLng? currentLocation,
    List<LatLng>? history,
  }) {
    return MapState(
      currentLocation: currentLocation ?? this.currentLocation,
      history: history ?? this.history,
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
    return const MapState();
  }

  Future<void> loadHistory() async {
    final logs = await ref.read(getLocationsUseCaseProvider).execute();

    // 各座標が有限数(Finite)であることを保証してから変換する
    final history = logs
        .map((e) => LatLng(
      e.latitude,
      e.longitude,
    ))
        .toList();

    state = state.copyWith(
      history: history,
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