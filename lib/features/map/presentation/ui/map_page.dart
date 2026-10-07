import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../common/constants/map_constants.dart';
import '../../../../core/app_info/install_date_provider.dart';
import '../../../location/domain/entities/timeline_item.dart';
import '../providers/map_provider.dart';
import 'widgets/timeline_sheet.dart';

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

      await vm.initialize();
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

  /// タイムラインで選んだ移動の経路を強調し、経路全体が見える位置に地図を動かす
  void _showRoute(Move move) {
    final viewModel = ref.read(mapProvider.notifier);

    // 選択中の移動をもう一度タップした場合は、強調を解除する
    if (ref.read(mapProvider).selectedMoveStart == move.start) {
      viewModel.clearSelectedMove();
      return;
    }

    final route = viewModel.selectMove(move);
    if (route.isEmpty) return;

    final size = MediaQuery.sizeOf(context);

    _controller.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(route),
        // 画面下部はタイムラインが重なるため、その分を空ける
        padding: EdgeInsets.fromLTRB(40, 40, 40, size.height * 0.3 + 40),
        maxZoom: MapConstants.currentLocationZoom,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mapProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${state.selectedDate.year}/${state.selectedDate.month}/${state.selectedDate.day}",
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              // アプリを使い始めた日より前は記録がないため選べないようにする
              final installDate = ref.read(installDateProvider);

              final selectedDate = await showDatePicker(
                context: context,
                initialDate: state.selectedDate,
                firstDate: DateTime(
                  installDate.year,
                  installDate.month,
                  installDate.day,
                ),
                lastDate: DateTime.now(),
              );

              if (selectedDate == null) {
                return;
              }

              await ref
                  .read(mapProvider.notifier)
                  .loadTimeline(selectedDate);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
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

              // 地図データの出典(OpenStreetMapの利用条件)
              // 画面下部はタイムラインが重なるため、上部に表示する
              const SimpleAttributionWidget(
                source: Text('OpenStreetMap contributors'),
                alignment: Alignment.topRight,
              ),

              // 履歴にもNaNが混入しないようフィルタリング
              if (state.history.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: state.history.where(_isValidLatLng).toList(),
                      strokeWidth: 4,
                      // 移動を選択している間は、全体の軌跡を薄くして経路を目立たせる
                      color: state.selectedRoute.isEmpty
                          ? Colors.blue
                          : Colors.blue.withValues(alpha: 0.35),
                    ),
                    // タイムラインで選択した移動の経路
                    if (state.selectedRoute.length >= 2)
                      Polyline(
                        points: state.selectedRoute,
                        strokeWidth: 7,
                        color: Colors.blue.shade900,
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
          if (state.timeline.isNotEmpty || state.isLoadingTimeline)
            TimelineSheet(
              items: state.timeline,
              isLoading: state.isLoadingTimeline,
              placeCandidates: state.placeCandidates,
              selectedMoveStart: state.selectedMoveStart,
              onStayTap: (stay) {
                ref.read(mapProvider.notifier).clearSelectedMove();

                _controller.move(
                  LatLng(stay.latitude, stay.longitude),
                  MapConstants.currentLocationZoom,
                );
              },
              onMoveTap: _showRoute,
              onPlaceNameChanged: (stay, placeName) {
                ref
                    .read(mapProvider.notifier)
                    .updateStayPlaceName(stay, placeName);
              },
              onTransportChanged: (move, transport, text) {
                ref
                    .read(mapProvider.notifier)
                    .updateMoveTransport(move, transport: transport, text: text);
              },
            ),
        ],
      ),
    );
  }
}