import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../common/constants/map_constants.dart';
import '../providers/map_provider.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  final MapController _controller = MapController();
  bool _movedToCurrentLocation = false; // 初回移動フラグ

  bool _isValidLatLng(LatLng loc) {
    return loc.latitude.isFinite &&
        loc.longitude.isFinite;
  }

  bool _hasValidCurrentLocation(LatLng? loc) {
    return loc != null &&
        _isValidLatLng(loc);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = ref.read(mapProvider.notifier);
      await vm.loadHistory();
      await vm.start();
    });

    ref.listenManual(
      mapProvider,
          (previous, next) {
            final loc = next.currentLocation;

            if (!_hasValidCurrentLocation(loc)) {
              return;
            }

            if (_movedToCurrentLocation) {
              return;
            }

            _movedToCurrentLocation = true;

            _controller.move(
              loc!,
              MapConstants.currentLocationZoom,
            );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mapProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Map"),
        /// デバッグ専用(保存した位置情報取得ボタン)
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () async {
              await ref
                  .read(mapProvider.notifier)
                  .debugPrintAllLocations();
            },
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _controller,
        options: MapOptions(
          initialCenter: LatLng(
            MapConstants.tokyoStationLat,
            MapConstants.tokyoStationLng,
          ),
          initialZoom: MapConstants.initialZoom,
          minZoom: MapConstants.minZoom,
          maxZoom: MapConstants.maxZoom,
          // 慣性アニメーションによる暴走を防ぐ
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.flingAnimation,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: MapConstants.tileUrl,
            userAgentPackageName: MapConstants.userAgent,
          ),

          // 履歴にもNaNが混入しないようフィルタリング
          if (state.history.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: state.history.where(_isValidLatLng).toList(),
                  strokeWidth: 4,
                  color: Colors.blue,
                ),
              ],
            ),

          if (_hasValidCurrentLocation(state.currentLocation))
            MarkerLayer(
              markers: [
                Marker(
                  point: state.currentLocation!,
                  width: MapConstants.markerSize,
                  height: MapConstants.markerSize,
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.blue,
                    size: MapConstants.markerSize,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}