import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:auto_diary_ai/common/constants/map_constants.dart';
import 'package:auto_diary_ai/features/map/presentation/providers/location_provider.dart';
import 'package:auto_diary_ai/features/map/data/services/location_service.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {

  final MapController _mapController = MapController();

  late LocationService _locationService;
  StreamSubscription<Position>? _locationSub;

  LatLng? currentLocation;

  @override
  void initState() {
    super.initState();

    _locationService = ref.read(locationServiceProvider);

    Future.microtask(() {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {

    // DB取得
    await _locationService.loadLocations();

    // GPS開始
    await _startLocation();

  }

  Future<void> _startLocation() async {

    await _locationService.start();

    _locationSub = _locationService.locationStream.listen((position) {

      final latlng = LatLng(position.latitude, position.longitude);

      setState(() {
        currentLocation = latlng;
      });

      _mapController.move(
        latlng,
        MapConstants.currentLocationZoom,
      );

    });
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _locationService.dispose();
    super.dispose();
  }

  void zoomIn() {
    final zoom = _mapController.camera.zoom;

    _mapController.move(
      _mapController.camera.center,
      zoom + 1,
    );
  }

  void zoomOut() {
    final zoom = _mapController.camera.zoom;

    _mapController.move(
      _mapController.camera.center,
      zoom - 1,
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Map"),
      ),
      body: Stack(
        children: [

          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(
                MapConstants.tokyoStationLat,
                MapConstants.tokyoStationLng,
              ),
              initialZoom: MapConstants.initialZoom,
            ),
            children: [

              TileLayer(
                urlTemplate: MapConstants.tileUrl,
                userAgentPackageName: MapConstants.userAgent,
              ),

              if (currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: currentLocation!,
                      width: MapConstants.markerSize,
                      height: MapConstants.markerSize,
                      child: const Icon(
                        Icons.my_location,
                        size: MapConstants.markerSize,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),

            ],
          ),

          Positioned(
            right: MapConstants.zoomButtonRight,
            bottom: MapConstants.zoomButtonBottom,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: "zoom_in",
                  mini: true,
                  onPressed: zoomIn,
                  child: const Icon(Icons.add),
                ),
                SizedBox(height: MapConstants.zoomButtonSpacing),
                FloatingActionButton(
                  heroTag: "zoom_out",
                  mini: true,
                  onPressed: zoomOut,
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }
}