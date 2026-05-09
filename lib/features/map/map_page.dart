import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:auto_diary_ai/common/constants/map_constants.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {

  final MapController _mapController = MapController();

  LatLng? currentLocation;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {

    // 位置情報サービス確認
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    // 権限確認
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    // GPS取得
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      currentLocation = LatLng(position.latitude, position.longitude);
    });

    // カメラ(地図の視点)移動
    _mapController.move(currentLocation!, MapConstants.currentLocationZoom);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Map"),
      ),
      body: FlutterMap(

        mapController: _mapController,

        options: MapOptions(
          initialCenter: LatLng(MapConstants.tokyoStationLat, MapConstants.tokyoStationLng),
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
    );
  }
}