import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../application/providers/location_providers.dart';
import '../../domain/entities/location.dart';

class MapState {

  final LatLng? currentLocation;

  const MapState({
    this.currentLocation,
  });

  MapState copyWith({
    LatLng? currentLocation,
  }) {

    return MapState(
      currentLocation:
      currentLocation ?? this.currentLocation,
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

    final logs = await ref
        .read(getLocationsUseCaseProvider)
        .execute();

    for (final log in logs) {

      print(
          "${log.latitude}, ${log.longitude}, ${log.timestamp}");

    }
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