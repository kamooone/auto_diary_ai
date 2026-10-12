import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../location/application/providers/location_providers.dart';
import '../../../location/domain/entities/place_candidate.dart';
import '../../../location/domain/repositories/place_search_repository.dart';
import '../../../location/domain/services/place_estimator.dart';

/// 入力した場所で、訪れた場所を取得できるかを確かめる画面(動作確認用)
///
/// タイムラインと同じ検索を、保存した結果を使わずに行う
class PlaceSearchTestPage extends ConsumerStatefulWidget {
  const PlaceSearchTestPage({super.key});

  @override
  ConsumerState<PlaceSearchTestPage> createState() =>
      _PlaceSearchTestPageState();
}

class _PlaceSearchTestPageState extends ConsumerState<PlaceSearchTestPage> {
  final _addressController = TextEditingController();
  final _coordinateController = TextEditingController();

  bool _isSearching = false;

  // 入力の誤りなど、検索の前に分かった問題
  String? _inputError;

  _SearchResult? _result;

  @override
  void dispose() {
    _addressController.dispose();
    _coordinateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;

    return Scaffold(
      appBar: AppBar(
        title: const Text("訪れた場所の取得テスト"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: "地名・住所",
              hintText: "東京駅",
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: "緯度・経度に変換",
                icon: const Icon(Icons.arrow_downward),
                onPressed: _isSearching ? null : _convertAddress,
              ),
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _convertAddress(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _coordinateController,
            decoration: const InputDecoration(
              labelText: "緯度, 経度",
              hintText: "35.681236, 139.767125",
              helperText: "地図アプリからコピーした座標をそのまま貼り付けられます",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _isSearching ? null : _search,
            child: const Text("訪れた場所を取得"),
          ),
          const SizedBox(height: 16),
          if (_isSearching) const Center(child: CircularProgressIndicator()),
          if (_inputError != null)
            Text(
              _inputError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          if (result != null && !_isSearching) ..._buildResult(context, result),
        ],
      ),
    );
  }

  List<Widget> _buildResult(BuildContext context, _SearchResult result) {
    final textTheme = Theme.of(context).textTheme;
    final error = result.error;
    final estimated = result.estimated;

    return [
      Text("結果", style: textTheme.titleMedium),
      const SizedBox(height: 8),
      _row("緯度, 経度", "${result.coordinate.latitude}, ${result.coordinate.longitude}"),
      _row("地名", result.placeName ?? "取得できませんでした"),
      _row("かかった時間", "${(result.elapsed.inMilliseconds / 1000).toStringAsFixed(1)}秒"),
      if (error != null) ...[
        _row("訪れた場所", "取得に失敗しました"),
        const SizedBox(height: 8),
        Text(
          error,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ] else ...[
        _row(
          "訪れた場所",
          estimated != null
              ? estimated.name
              : "なし(周辺に施設がないため、地名で表示されます)",
        ),
        const SizedBox(height: 16),
        Text("周辺の施設(${result.candidates.length}件)", style: textTheme.titleMedium),
        if (result.candidates.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text("周辺に施設が登録されていません"),
          ),
        for (final candidate in result.candidates)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              candidate == estimated ? Icons.check_circle : Icons.place,
              color: candidate == estimated ? Colors.green : Colors.grey,
            ),
            title: Text(candidate.name),
            subtitle: Text(
              [
                "${candidate.distanceMeters.round()}m",
                if (candidate.category != null) candidate.category!,
              ].join(" ・ "),
            ),
          ),
      ],
    ];
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 104, child: Text(label)),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }

  /// 地名・住所を緯度・経度に変換して、入力欄に入れる
  Future<void> _convertAddress() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) return;

    setState(() {
      _isSearching = true;
      _inputError = null;
      _result = null;
    });

    Coordinate? coordinate;
    String? error;

    try {
      coordinate = await ref
          .read(addressSearchDataSourceProvider)
          .findCoordinate(address);

      if (coordinate == null) error = "「$address」の場所が見つかりませんでした";
    } catch (e) {
      error = "「$address」の場所を調べられませんでした: $e";
    }

    if (!mounted) return;

    setState(() {
      _isSearching = false;
      _inputError = error;

      if (coordinate != null) {
        _coordinateController.text =
            "${coordinate.latitude}, ${coordinate.longitude}";
      }
    });
  }

  Future<void> _search() async {
    final coordinate = _parseCoordinate(_coordinateController.text);

    if (coordinate == null) {
      setState(() {
        _inputError = "緯度と経度を「35.681236, 139.767125」の形で入力してください";
        _result = null;
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSearching = true;
      _inputError = null;
      _result = null;
    });

    final placeName = await ref
        .read(placeNameRepositoryProvider)
        .getPlaceName(coordinate.latitude, coordinate.longitude);

    final stopwatch = Stopwatch()..start();

    var candidates = <PlaceCandidate>[];
    String? error;

    try {
      candidates =
          await ref.read(placeSearchRepositoryProvider).search(coordinate);
    } catch (e) {
      error = e.toString();
    }

    stopwatch.stop();

    if (!mounted) return;

    setState(() {
      _isSearching = false;
      _result = _SearchResult(
        coordinate: coordinate,
        placeName: placeName,
        candidates: candidates,
        estimated: PlaceEstimator().estimate(candidates),
        error: error,
        elapsed: stopwatch.elapsed,
      );
    });
  }

  Coordinate? _parseCoordinate(String text) {
    final parts = text
        .split(RegExp(r"[,、\s]+"))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.length != 2) return null;

    final latitude = double.tryParse(parts[0]);
    final longitude = double.tryParse(parts[1]);
    if (latitude == null || longitude == null) return null;
    if (latitude.abs() > 90 || longitude.abs() > 180) return null;

    return (latitude: latitude, longitude: longitude);
  }
}

class _SearchResult {
  final Coordinate coordinate;

  /// 座標から取得した地名(取得できなかった場合はnull)
  final String? placeName;

  /// 周辺の施設の候補(近い順)
  final List<PlaceCandidate> candidates;

  /// タイムラインで訪れた場所として表示される施設(ない場合はnull)
  final PlaceCandidate? estimated;

  /// 施設を検索できなかった理由(検索できた場合はnull)
  final String? error;

  /// 施設の検索にかかった時間
  final Duration elapsed;

  const _SearchResult({
    required this.coordinate,
    required this.placeName,
    required this.candidates,
    required this.estimated,
    required this.error,
    required this.elapsed,
  });
}
