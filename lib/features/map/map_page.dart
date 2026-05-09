import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:auto_diary_ai/services/location_service.dart';
import 'package:auto_diary_ai/common/constants/map_constants.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {

  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();

  StreamSubscription<Position>? _locationSub;

  LatLng? currentLocation;

  @override
  void initState() {
    super.initState();
    _startLocation();
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
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1);
  }

  void zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
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