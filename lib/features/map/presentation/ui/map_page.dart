import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../common/constants/map_constants.dart';
import '../providers/map_provider.dart';

class MapPage extends ConsumerStatefulWidget {

  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() =>
      _MapPageState();
}

class _MapPageState
    extends ConsumerState<MapPage> {

  final MapController _controller =
  MapController();

  @override
  void initState() {

    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback((_) async {

      final vm =
      ref.read(mapProvider.notifier);

      await vm.loadHistory();

      await vm.start();

    });

    ref.listenManual(
      mapProvider,
          (previous, next) {

        if (next.currentLocation == null) {
          return;
        }

        _controller.move(
          next.currentLocation!,
          MapConstants.currentLocationZoom,
        );

      },
    );
  }

  @override
  Widget build(BuildContext context) {

    final state =
    ref.watch(mapProvider);

    return Scaffold(

      appBar: AppBar(
        title: const Text("Map"),
      ),

      body: FlutterMap(

        mapController: _controller,

        options: MapOptions(

          initialCenter: LatLng(
            MapConstants.tokyoStationLat,
            MapConstants.tokyoStationLng,
          ),

          initialZoom:
          MapConstants.initialZoom,

          minZoom:
          MapConstants.minZoom,

          maxZoom:
          MapConstants.maxZoom,

        ),

        children: [

          TileLayer(

            urlTemplate:
            MapConstants.tileUrl,

            userAgentPackageName:
            MapConstants.userAgent,

          ),

          if (state.currentLocation != null)

            MarkerLayer(

              markers: [

                Marker(

                  point:
                  state.currentLocation!,

                  width:
                  MapConstants.markerSize,

                  height:
                  MapConstants.markerSize,

                  child: const Icon(
                    Icons.my_location,
                    color: Colors.blue,
                    size:
                    MapConstants.markerSize,
                  ),

                ),

              ],

            ),

        ],

      ),

    );

  }

}