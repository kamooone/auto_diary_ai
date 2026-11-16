import 'package:flutter/material.dart';
import '../../../../common/constants/app_colors.dart';
import '../../../../common/constants/app_sizes.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../common/constants/map_constants.dart';
import '../../../../core/app_info/install_date_provider.dart';
import '../../../../core/logging/app_log_panel.dart';
import '../../../location/domain/entities/timeline_item.dart';
import '../../../tutorial/application/tutorial_providers.dart';
import '../../../tutorial/domain/tutorial_step.dart';
import '../../../tutorial/presentation/tutorial_runner.dart';
import '../providers/map_provider.dart';
import 'widgets/timeline_sheet.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  final MapController _controller = MapController();

  // タイムラインのシートの高さを操作する
  final _sheetController = DraggableScrollableController();
  bool _movedToCurrentLocation = false; // 初回移動フラグ

  // 動作確認用のログを表示するか
  bool _showLog = true;

  // チュートリアルで明るくする部品
  final _timelineKey = GlobalKey();

  // この画面のチュートリアルの印(見たかどうかを覚えるときの名前)
  static const _tutorialId = 'map';

  bool _isValidLatLng(LatLng loc) {
    return loc.latitude.isFinite && loc.longitude.isFinite;
  }

  bool _hasValidCurrentLocation(LatLng? loc) {
    return loc != null && _isValidLatLng(loc);
  }

  @override
  void dispose() {
    _controller.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = ref.read(mapProvider.notifier);

      await vm.initialize();

      // 初めて表示したときは、先にチュートリアルを出す(位置情報の許可の確認は、そのあと)
      await _showTutorialOnce();
      if (!mounted) return;

      await vm.start();
    });

    ref.listenManual(mapProvider, (previous, next) {
      final loc = next.currentLocation;

      if (!_hasValidCurrentLocation(loc)) {
        return;
      }

      if (_movedToCurrentLocation) {
        return;
      }

      _movedToCurrentLocation = true;

      _controller.move(loc!, MapConstants.currentLocationZoom);
    });
  }

  // 初めて表示したときだけ、説明する
  Future<void> _showTutorialOnce() async {
    final store = ref.read(tutorialSeenStoreProvider);
    if (await store.hasSeen(_tutorialId)) return;
    if (!mounted) return;

    await showTutorial(context, [
      const TutorialStep.intro(
        title: "行動履歴",
        body: "地図に、現在地と、選んだ日の移動の軌跡が表示されます。\n※行動履歴を取得するには位置情報取得の許可が必要です。",
      ),
      TutorialStep(
        target: _timelineKey,
        title: "タイムライン",
        bubbleAbove: true,
        body:
            "その日の滞在と移動が並びます。\n行動履歴の内容は正確ではないので、鉛筆のボタンで場所の名前や移動手段を直すことができます。\nこのタイムラインの情報はAIに日記を作成してもらうときに使用することができます。",
      ),
    ]);

    await store.markSeen(_tutorialId);
  }

  /// タイムラインのシートを最も小さくする
  /// (タイムラインをタップして地図を動かしたときに、その場所がシートに隠れないようにする)
  void _collapseSheet() {
    if (!_sheetController.isAttached) return;

    _sheetController.animateTo(
      TimelineSheet.minSize,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
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

    _collapseSheet();

    final size = MediaQuery.sizeOf(context);

    _controller.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(route),
        // 画面下部は小さくしたタイムラインが重なるため、その分を空ける
        padding: EdgeInsets.fromLTRB(
          40,
          40,
          40,
          size.height * TimelineSheet.minSize + 40,
        ),
        maxZoom: MapConstants.currentLocationZoom,
      ),
    );
  }

  /// 表示する日を切り替える
  void _changeDate(DateTime date) {
    ref.read(mapProvider.notifier).loadTimeline(date);
  }

  /// カレンダーから表示する日を選ぶ
  Future<void> _pickDate({
    required DateTime firstDay,
    required DateTime lastDay,
  }) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: ref.read(mapProvider).selectedDate,
      firstDate: firstDay,
      lastDate: lastDay,
    );

    if (selectedDate != null) {
      _changeDate(selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mapProvider);

    // 切り替えられる日の範囲(アプリを使い始めた日から今日まで)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final installDate = ref.watch(installDateProvider);
    final firstDay = DateTime(
      installDate.year,
      installDate.month,
      installDate.day,
    );
    final selectedDay = DateTime(
      state.selectedDate.year,
      state.selectedDate.month,
      state.selectedDate.day,
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: '戻る',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text("行動履歴"),
      ),
      // シートの高さに合わせて、地図の上の部品(出典、デバッグボタン)を、シートの少し上に置く
      body: LayoutBuilder(
        builder: (context, constraints) => Stack(
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

                // 履歴にもNaNが混入しないようフィルタリング
                // 移動のルート(白い線の上に、オレンジの点線)
                if (state.history.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      // 移動を選択している間は、全体の軌跡を薄くして、選んだ経路を目立たせる
                      ..._routeLines(
                        state.history.where(_isValidLatLng).toList(),
                        opacity: state.selectedRoute.isEmpty ? 1 : 0.35,
                      ),
                      // タイムラインで選択した移動の経路
                      if (state.selectedRoute.length >= 2)
                        ..._routeLines(state.selectedRoute),
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
            // 記録のない日でも日付を切り替えられるよう、シートは常に表示する
            TimelineSheet(
              sheetKey: _timelineKey,
              controller: _sheetController,
              date: state.selectedDate,
              canGoToPreviousDay: selectedDay.isAfter(firstDay),
              canGoToNextDay: selectedDay.isBefore(today),
              onPreviousDay: () => _changeDate(
                DateTime(
                  selectedDay.year,
                  selectedDay.month,
                  selectedDay.day - 1,
                ),
              ),
              onNextDay: () => _changeDate(
                DateTime(
                  selectedDay.year,
                  selectedDay.month,
                  selectedDay.day + 1,
                ),
              ),
              onDateTap: () => _pickDate(firstDay: firstDay, lastDay: today),
              items: state.timeline,
              isLoading: state.isLoadingTimeline,
              placeCandidates: state.placeCandidates,
              selectedMoveStart: state.selectedMoveStart,
              onStayTap: (stay) {
                ref.read(mapProvider.notifier).clearSelectedMove();
                _collapseSheet();

                _controller.move(
                  LatLng(stay.latitude, stay.longitude),
                  MapConstants.currentLocationZoom,
                );
              },
              onMoveTap: _showRoute,
              onRetryPlaceSearch: () {
                ref.read(mapProvider.notifier).retryPlaceSearch();
              },
              onPlaceNameChanged: (stay, placeName, {registerPlace = false}) {
                ref
                    .read(mapProvider.notifier)
                    .updateStayPlaceName(
                      stay,
                      placeName,
                      registerPlace: registerPlace,
                    );
              },
              onTransportChanged: (move, transport, text) {
                ref
                    .read(mapProvider.notifier)
                    .updateMoveTransport(
                      move,
                      transport: transport,
                      text: text,
                    );
              },
            ),
            // 動作確認用のログ
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: _showLog
                      ? AppLogPanel(
                          onClose: () => setState(() => _showLog = false),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),

            // 地図データの出典(OpenStreetMapの利用条件)と、デバッグボタン
            // どちらも、シートに隠れないよう、シートの少し上に置く
            ListenableBuilder(
              listenable: _sheetController,
              builder: (context, _) {
                final sheetSize = _sheetController.isAttached
                    ? _sheetController.size
                    : 0.25;
                final bottom = constraints.maxHeight * sheetSize;

                return Stack(
                  children: [
                    Positioned(
                      left: AppSizes.space8,
                      bottom: bottom + AppSizes.space4,
                      child: const _MapAttribution(),
                    ),
                    if (!_showLog)
                      Positioned(
                        right: AppSizes.space16,
                        bottom: bottom + AppSizes.space12,
                        child: _DebugButton(
                          onPressed: () => setState(() => _showLog = true),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// 移動のルートの線: 白い線(太さ8)の上に、オレンジの点線(太さ4、丸い端、点2・間7)
List<Polyline> _routeLines(List<LatLng> points, {double opacity = 1}) {
  return [
    Polyline(
      points: points,
      strokeWidth: 8,
      color: AppColors.white.withValues(alpha: opacity),
    ),
    Polyline(
      points: points,
      strokeWidth: 4,
      color: AppColors.orange.withValues(alpha: opacity),
      strokeCap: StrokeCap.round,
      pattern: StrokePattern.dashed(segments: const [2, 7]),
    ),
  ];
}

/// 地図の出典(OpenStreetMapの利用条件)。地図の左下に、小さく出す
class _MapAttribution extends StatelessWidget {
  const _MapAttribution();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          '© OpenStreetMap contributors',
          style: TextStyle(fontSize: 10, color: AppColors.textSub),
        ),
      ),
    );
  }
}

/// デバッグ用のボタン(ログを表示する)
class _DebugButton extends StatelessWidget {
  const _DebugButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.line),
        boxShadow: AppColors.cardShadows,
      ),
      child: IconButton(
        onPressed: onPressed,
        tooltip: 'ログを表示',
        padding: EdgeInsets.zero,
        icon: const Icon(
          Icons.bug_report_outlined,
          size: 20,
          color: AppColors.navy,
        ),
      ),
    );
  }
}
