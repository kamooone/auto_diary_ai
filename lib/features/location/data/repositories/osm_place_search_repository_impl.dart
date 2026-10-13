import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../../../../core/logging/app_log.dart';
import '../../domain/entities/place_candidate.dart';
import '../../domain/exceptions/place_search_exception.dart';
import '../../domain/repositories/place_search_repository.dart';
import '../datasources/place_candidate_cache.dart';

/// OpenStreetMap(Overpass API)で周辺の施設を検索する
class OsmPlaceSearchRepositoryImpl implements PlaceSearchRepository {
  final http.Client _client;

  // 同じ場所を何度も問い合わせないよう、検索結果を保存して再利用する
  final PlaceCandidateCache _cache;

  // 問い合わせ先(先頭から順に試し、応答がなければ次のサーバーに切り替える)
  final List<Uri> _endpoints;

  OsmPlaceSearchRepositoryImpl({
    http.Client? client,
    PlaceCandidateCache? cache,
    List<Uri>? endpoints,
  })  : _client = client ?? http.Client(),
        _cache = cache ?? MemoryPlaceCandidateCache(),
        _endpoints = endpoints ?? defaultEndpoints;

  static final defaultEndpoints = [
    Uri.parse('https://overpass-api.de/api/interpreter'),
    Uri.parse('https://overpass.kumi.systems/api/interpreter'),
    Uri.parse('https://overpass.private.coffee/api/interpreter'),
  ];

  // 公開サーバーの利用条件として、アプリを識別できる情報を送る
  static const _userAgent = 'auto_diary_ai/1.0';

  // 1回の問い合わせを待つ時間(サーバー側の制限[_serverTimeoutSeconds]より少し長くする)
  static const _timeout = Duration(seconds: 8);

  static const _serverTimeoutSeconds = 6;

  // 別のサーバーに切り替えながら取得を試す時間の上限
  static const _maxRequestDuration = Duration(seconds: 10);

  // 滞在場所からこの距離以内にある施設を候補にする
  static const _radiusMeters = 75;

  // 1か所あたりの候補の上限
  static const _maxCandidates = 8;

  // 1回の問い合わせで受け取る施設の上限
  static const _maxElements = 300;

  // 場所を分けて取り直すのは、検索を始めてからこの時間まで
  // (これを過ぎても取得できていない場所は、取得できなかったものとして扱う)
  static const _maxSearchDuration = Duration(seconds: 15);

  // 検索する施設の種類(タグのキー)
  static const _facilityKeys = ['amenity', 'shop', 'tourism', 'leisure', 'office'];

  // 滞在先とは考えにくい設備
  static const _excludedAmenities = {
    'parking',
    'parking_space',
    'parking_entrance',
    'bicycle_parking',
    'motorcycle_parking',
    'vending_machine',
    'toilets',
    'atm',
    'post_box',
    'bench',
    'waste_basket',
    'drinking_water',
    'telephone',
    'taxi',
  };

  @override
  Future<List<List<PlaceCandidate>?>> findNearby(
    List<Coordinate> coordinates,
  ) async {
    final stopwatch = Stopwatch()..start();
    final results = <String, List<PlaceCandidate>>{};
    final missing = <Coordinate>[];

    for (final coordinate in coordinates) {
      final key = _key(coordinate);
      if (results.containsKey(key)) continue;

      final cached = await _cache.get(key);
      if (cached != null) {
        results[key] = cached;
      } else if (!missing.any((e) => _key(e) == key)) {
        missing.add(coordinate);
      }
    }

    AppLog.add(
      '施設',
      '保存済み${results.length}か所 / 取得が必要${missing.length}か所 '
          '(キャッシュ確認 ${stopwatch.elapsedMilliseconds}ms)',
    );

    if (missing.isNotEmpty) {
      // まずは1回の問い合わせにまとめる
      await _search(missing, results, Stopwatch()..start());
    }

    // 取得できなかった場所はnullのままになる
    final found = [
      for (final coordinate in coordinates) results[_key(coordinate)],
    ];

    AppLog.add(
      '施設',
      '検索完了: 取得${found.where((e) => e != null).length}か所 / '
          '失敗${found.where((e) => e == null).length}か所 '
          '(${stopwatch.elapsedMilliseconds}ms)',
    );

    return found;
  }

  @override
  Future<List<PlaceCandidate>> search(Coordinate coordinate) async {
    try {
      return _candidates(coordinate, await _request([coordinate]));
    } catch (e) {
      throw PlaceSearchException('$e');
    }
  }

  // 小数第4位(約10m)で丸めた座標をキーにする
  String _key(Coordinate coordinate) {
    return '${coordinate.latitude.toStringAsFixed(4)},'
        '${coordinate.longitude.toStringAsFixed(4)}';
  }

  /// [coordinates]の周辺の施設を検索し、取得できた場所の候補を[results]に入れて保存する
  ///
  /// まとめた問い合わせをサーバーが処理しきれなかった場合は、場所を半分に分けて取り直す
  /// (1か所のせいで、ほかの場所まで取得できなくならないようにする)
  Future<void> _search(
    List<Coordinate> coordinates,
    Map<String, List<PlaceCandidate>> results,
    Stopwatch stopwatch,
  ) async {
    if (stopwatch.elapsed >= _maxSearchDuration) {
      AppLog.add('施設', '${coordinates.length}か所: 制限時間を過ぎたため取得しません');
      return;
    }

    final List<Map<String, dynamic>> elements;

    try {
      elements = await _request(coordinates);
    } on _IncompleteResultException {
      AppLog.add('施設', '${coordinates.length}か所: 処理しきれず、分けて取り直します');
      await _searchSeparately(coordinates, results, stopwatch);
      return;
    } catch (e) {
      // 通信できない場合などは、分けて取り直しても同じ結果になる
      AppLog.add('施設', '${coordinates.length}か所: 取得失敗 ($e)');
      return;
    }

    // 上限まで返ってきた場合は、一部の場所の施設が欠けている可能性がある
    // (欠けたまま「周辺に施設がない」と保存しないよう、場所を分けて取り直す)
    if (elements.length >= _maxElements && coordinates.length > 1) {
      AppLog.add('施設', '${coordinates.length}か所: 件数が上限に達したため、分けて取り直します');
      await _searchSeparately(coordinates, results, stopwatch);
      return;
    }

    for (final coordinate in coordinates) {
      final key = _key(coordinate);
      final candidates = _candidates(coordinate, elements);

      results[key] = candidates;
      await _cache.put(key, candidates);
    }
  }

  Future<void> _searchSeparately(
    List<Coordinate> coordinates,
    Map<String, List<PlaceCandidate>> results,
    Stopwatch stopwatch,
  ) async {
    // 1か所だけでも取得できない場合は、これ以上分けられない
    if (coordinates.length == 1) return;

    final half = coordinates.length ~/ 2;

    await _search(coordinates.sublist(0, half), results, stopwatch);
    await _search(coordinates.sublist(half), results, stopwatch);
  }

  Future<List<Map<String, dynamic>>> _request(
    List<Coordinate> coordinates,
  ) async {
    final query = _buildQuery(coordinates);
    final stopwatch = Stopwatch()..start();

    Object? lastError;
    _IncompleteResultException? incomplete;

    for (final endpoint in _endpoints) {
      // 時間をかけすぎないよう、次のサーバーへの切り替えは上限の時間までにする
      if (lastError != null && stopwatch.elapsed >= _maxRequestDuration) break;

      final attempt = Stopwatch()..start();

      try {
        final elements = await _post(endpoint, query);
        AppLog.add(
          '施設',
          '${endpoint.host}: ${coordinates.length}か所 → ${elements.length}件 '
              '${attempt.elapsedMilliseconds}ms',
        );
        return elements;
      } on _IncompleteResultException catch (e) {
        incomplete = e;
        lastError = e;
        AppLog.add(
          '施設',
          '${endpoint.host}: 処理しきれず ${attempt.elapsedMilliseconds}ms ($e)',
        );

        // 複数の場所をまとめた問い合わせは、サーバーを変えるより場所を分けた方が早い
        if (coordinates.length > 1) rethrow;
      } catch (e) {
        lastError = e;
        AppLog.add(
          '施設',
          '${endpoint.host}: 失敗 ${attempt.elapsedMilliseconds}ms ($e)',
        );
      }
    }

    // 処理しきれなかったサーバーがあった場合は、場所を分けて取り直せる可能性がある
    throw incomplete ?? lastError ?? Exception('問い合わせ先がありません');
  }

  // 施設の種類を指定して検索する(キーを正規表現で指定するより速い)
  String _buildQuery(List<Coordinate> coordinates) {
    final statements = StringBuffer();

    for (final coordinate in coordinates) {
      final around =
          'around:$_radiusMeters,${coordinate.latitude},${coordinate.longitude}';

      for (final key in _facilityKeys) {
        statements.writeln('nwr($around)[name][$key];');
      }
      statements.writeln('nwr($around)[name][railway~"^(station|halt)\$"];');
    }

    return '[out:json][timeout:$_serverTimeoutSeconds];($statements);'
        'out center tags $_maxElements;';
  }

  Future<List<Map<String, dynamic>>> _post(Uri endpoint, String query) async {
    final response = await _client.post(
      endpoint,
      headers: {'User-Agent': _userAgent},
      body: {'data': query},
    ).timeout(_timeout);

    // 504は、サーバーが時間内に検索を終えられなかった場合に返る
    if (response.statusCode == 504) {
      throw _IncompleteResultException('${response.statusCode}');
    }

    if (response.statusCode != 200) {
      throw Exception('Overpass API: ${response.statusCode}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is! Map<String, dynamic>) {
      throw Exception('Overpass API: 応答の形式が想定と異なります');
    }

    // 検索が時間切れなどで打ち切られた場合は、200のまま途中までの結果とremarkが返る
    final remark = data['remark'];
    if (remark is String && remark.isNotEmpty) {
      throw _IncompleteResultException(remark);
    }

    final elements = data['elements'];
    if (elements is! List) {
      throw Exception('Overpass API: 応答の形式が想定と異なります');
    }

    return [
      for (final element in elements)
        if (element is Map<String, dynamic>) element,
    ];
  }

  List<PlaceCandidate> _candidates(
    Coordinate coordinate,
    List<Map<String, dynamic>> elements,
  ) {
    final candidates = <PlaceCandidate>[];
    final names = <String>{};

    for (final element in elements) {
      final tags = element['tags'];
      if (tags is! Map<String, dynamic>) continue;

      if (_excludedAmenities.contains(tags['amenity'])) continue;

      final rawName = tags['name:ja'] ?? tags['name'];
      if (rawName is! String || rawName.isEmpty) continue;

      final category = _category(tags);

      // 駅は「東京」のように駅名だけが登録されているため「駅」を補う
      final name = category == '駅' && !rawName.endsWith('駅')
          ? '$rawName駅'
          : rawName;

      // 建物などは中心点の座標が入る
      final center = element['center'];
      final latitude = element['lat'] ?? (center is Map ? center['lat'] : null);
      final longitude = element['lon'] ?? (center is Map ? center['lon'] : null);
      if (latitude is! num || longitude is! num) continue;

      final distance = _distance(
        coordinate.latitude,
        coordinate.longitude,
        latitude.toDouble(),
        longitude.toDouble(),
      );
      if (distance > _radiusMeters) continue;

      // 同じ名前の施設(建物と入口など)は1つにまとめる
      if (!names.add(name)) continue;

      candidates.add(
        PlaceCandidate(
          name: name,
          category: category,
          distanceMeters: distance,
        ),
      );
    }

    candidates.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

    return candidates.take(_maxCandidates).toList();
  }

  String? _category(Map<String, dynamic> tags) {
    if (tags['railway'] != null) return '駅';

    const labels = {
      'cafe': 'カフェ',
      'restaurant': 'レストラン',
      'fast_food': 'ファストフード',
      'bar': 'バー',
      'pub': '居酒屋',
      'convenience': 'コンビニ',
      'supermarket': 'スーパー',
      'department_store': 'デパート',
      'mall': 'ショッピングモール',
      'bakery': 'パン屋',
      'books': '書店',
      'clothes': '衣料品店',
      'hairdresser': '美容院',
      'chemist': 'ドラッグストア',
      'pharmacy': '薬局',
      'hospital': '病院',
      'clinic': '診療所',
      'dentist': '歯科',
      'school': '学校',
      'university': '大学',
      'library': '図書館',
      'bank': '銀行',
      'post_office': '郵便局',
      'cinema': '映画館',
      'place_of_worship': '寺社・教会',
      'fuel': 'ガソリンスタンド',
      'hotel': 'ホテル',
      'museum': '博物館・美術館',
      'attraction': '観光スポット',
      'park': '公園',
      'fitness_centre': 'ジム',
      'sports_centre': 'スポーツ施設',
    };

    for (final key in ['amenity', 'shop', 'tourism', 'leisure']) {
      final label = labels[tags[key]];
      if (label != null) return label;
    }

    if (tags['shop'] != null) return '店舗';
    if (tags['office'] != null) return 'オフィス';

    return null;
  }

  // 2点間の距離(m)
  double _distance(double lat1, double lng1, double lat2, double lng2) {
    const earthRadius = 6371000.0;
    const toRadians = pi / 180;

    final dLat = (lat2 - lat1) * toRadians;
    final dLng = (lng2 - lng1) * toRadians;

    final h = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * toRadians) *
            cos(lat2 * toRadians) *
            sin(dLng / 2) *
            sin(dLng / 2);

    return 2 * earthRadius * asin(min(1.0, sqrt(h)));
  }
}

/// 問い合わせが重く、サーバーが検索を終えられなかった(場所を減らせば取得できる可能性がある)
class _IncompleteResultException implements Exception {
  final String message;

  _IncompleteResultException(this.message);

  @override
  String toString() => 'Overpass API: $message';
}
