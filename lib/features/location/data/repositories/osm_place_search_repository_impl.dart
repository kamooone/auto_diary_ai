import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../../../../core/async/parallel.dart';
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

  // 問い合わせ先(問い合わせを振り分け、応答がなければ次のサーバーに切り替える)
  final List<Uri> _endpoints;

  // 1回の問い合わせを待つ時間
  final Duration _timeout;

  // 応答がないとき、この時間を過ぎたら次のサーバーにも同時に問い合わせる
  final Duration _hedgeDelay;

  // 失敗したサーバーと、そのときの時刻(しばらく後回しにする)
  final _failedAt = <Uri, DateTime>{};

  OsmPlaceSearchRepositoryImpl({
    http.Client? client,
    PlaceCandidateCache? cache,
    List<Uri>? endpoints,
    Duration timeout = const Duration(seconds: 12),
    Duration hedgeDelay = const Duration(seconds: 4),
  })  : _client = client ?? http.Client(),
        _cache = cache ?? MemoryPlaceCandidateCache(),
        _endpoints = endpoints ?? defaultEndpoints,
        _timeout = timeout,
        _hedgeDelay = hedgeDelay;

  // 応答を確認できたサーバー(応答のなかったミラーは入れない)
  static final defaultEndpoints = [
    Uri.parse('https://overpass-api.de/api/interpreter'),
    Uri.parse('https://overpass.openstreetmap.fr/api/interpreter'),
  ];

  // 1回の問い合わせにまとめる場所の数
  // (まとめるほど重くなり、4か所では約8秒かかって打ち切られたため、少数ずつ並行して問い合わせる)
  static const _chunkSize = 2;

  // 同時に問い合わせる数(公開サーバーに負荷をかけすぎない)
  static const _concurrency = 4;

  // 公開サーバーの利用条件として、アプリを識別できる情報を送る
  static const _userAgent = 'auto_diary_ai/1.0';

  // 滞在場所からこの距離以内にある施設を候補にする
  static const _radiusMeters = 75;

  // 1か所あたりの候補の上限
  static const _maxCandidates = 8;

  // 1回の問い合わせで受け取る施設の上限
  static const _maxElements = 300;

  // サーバー側で検索を打ち切る時間
  static const _serverTimeoutSeconds = 10;

  // 失敗したサーバーを後回しにする時間
  static const _failureMemory = Duration(minutes: 5);

  // 場所を分けて取り直すのは、検索を始めてからこの時間まで
  // (これを過ぎても取得できていない場所は、取得できなかったものとして扱う)
  static const _maxSearchDuration = Duration(seconds: 25);

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
      // 少数ずつに分け、サーバーを振り分けて並行して問い合わせる
      final search = Stopwatch()..start();
      final chunks = [
        for (var i = 0; i < missing.length; i += _chunkSize)
          missing.sublist(i, min(i + _chunkSize, missing.length)),
      ];

      var index = 0;
      await parallelMap(
        chunks,
        (chunk) => _search(chunk, results, search, index++),
        concurrency: _concurrency,
      );
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
    int first,
  ) async {
    if (stopwatch.elapsed >= _maxSearchDuration) {
      AppLog.add('施設', '${coordinates.length}か所: 制限時間を過ぎたため取得しません');
      return;
    }

    final List<Map<String, dynamic>> elements;

    try {
      elements = await _request(coordinates, first);
    } on _IncompleteResultException {
      AppLog.add('施設', '${coordinates.length}か所: 処理しきれず、分けて取り直します');
      await _searchSeparately(coordinates, results, stopwatch, first);
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
      await _searchSeparately(coordinates, results, stopwatch, first);
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
    int first,
  ) async {
    // 1か所だけでも取得できない場合は、これ以上分けられない
    if (coordinates.length == 1) return;

    final half = coordinates.length ~/ 2;

    await Future.wait([
      _search(coordinates.sublist(0, half), results, stopwatch, first),
      _search(coordinates.sublist(half), results, stopwatch, first + 1),
    ]);
  }

  // 最近失敗したサーバーを後ろにして、[first]番目から順に並べる(問い合わせごとに変えて振り分ける)
  List<Uri> _orderedEndpoints(int first) {
    final now = DateTime.now();

    bool isHealthy(Uri endpoint) {
      final failedAt = _failedAt[endpoint];
      return failedAt == null || now.difference(failedAt) > _failureMemory;
    }

    final healthy = [
      for (final endpoint in _endpoints)
        if (isHealthy(endpoint)) endpoint,
    ];
    final failed = [
      for (final endpoint in _endpoints)
        if (!isHealthy(endpoint)) endpoint,
    ];

    final shift = healthy.isEmpty ? 0 : first % healthy.length;

    return [...healthy.sublist(shift), ...healthy.sublist(0, shift), ...failed];
  }

  /// サーバーに問い合わせる
  ///
  /// 応答が遅い場合は、待たずに次のサーバーにも同時に問い合わせ、先に取得できた結果を使う
  Future<List<Map<String, dynamic>>> _request(
    List<Coordinate> coordinates, [
    int first = 0,
  ]) {
    final query = _buildQuery(coordinates);
    final order = _orderedEndpoints(first);
    final completer = Completer<List<Map<String, dynamic>>>();

    var started = 0;
    var pending = 0;
    Object? lastError;
    var isIncomplete = false;
    Timer? hedge;

    void finish(Object? error, List<Map<String, dynamic>>? elements) {
      if (completer.isCompleted) return;
      hedge?.cancel();

      if (elements != null) {
        completer.complete(elements);
        return;
      }

      // 処理しきれなかった・待ちきれなかった場合は、場所を分けると取得できる可能性がある
      completer.completeError(
        isIncomplete && coordinates.length > 1
            ? _IncompleteResultException('$error')
            : error ?? Exception('問い合わせ先がありません'),
      );
    }

    void startNext() {
      if (completer.isCompleted || started >= order.length) return;

      final endpoint = order[started++];
      pending++;

      hedge?.cancel();
      if (started < order.length) hedge = Timer(_hedgeDelay, startNext);

      final attempt = Stopwatch()..start();

      _post(endpoint, query).then((elements) {
        pending--;
        _failedAt.remove(endpoint);
        AppLog.add(
          '施設',
          '${endpoint.host}: ${coordinates.length}か所 → ${elements.length}件 '
              '${attempt.elapsedMilliseconds}ms',
        );
        finish(null, elements);
      }, onError: (Object e) {
        pending--;
        lastError = e;
        _failedAt[endpoint] = DateTime.now();
        if (e is _IncompleteResultException || e is TimeoutException) {
          isIncomplete = true;
        }
        // 別のサーバーで取得できたあとに、遅れて失敗が分かる場合がある(結果には影響しない)
        AppLog.add(
          '施設',
          '${endpoint.host}: '
              '${e is _IncompleteResultException ? '処理しきれず' : '失敗'} '
              '${attempt.elapsedMilliseconds}ms ($e)'
              '${completer.isCompleted ? ' ※別のサーバーで取得済み' : ''}',
        );

        if (completer.isCompleted || pending > 0) return;

        // 取得中のものがなければ、次のサーバーに切り替える
        if (started < order.length) {
          startNext();
        } else {
          finish(lastError, null);
        }
      });
    }

    startNext();

    return completer.future;
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
          floor: _floor(tags),
        ),
      );
    }

    candidates.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

    return candidates.take(_maxCandidates).toList();
  }

  // 階の表示(「2階」「1・2階」「地下1階」)。登録がない・読み取れない場合はnull
  //
  // OSMでは、日本の建物は1階が「1」、地下1階が「-1」と登録されることが多い。
  // 「0」は1階を指すのか判断できないため、表示しない。
  String? _floor(Map<String, dynamic> tags) {
    final raw = tags['level'] ?? tags['addr:floor'];
    if (raw is! String) return null;

    final levels = <int>[];
    for (final part in raw.split(';')) {
      final level = int.tryParse(part.trim());
      if (level == null || level == 0) return null;
      levels.add(level);
    }
    if (levels.isEmpty) return null;

    // 地上と地下にまたがる場合など、まとめて表せないものは表示しない
    if (levels.any((e) => e < 0) && levels.any((e) => e > 0)) return null;

    levels.sort((a, b) => a.abs().compareTo(b.abs()));
    final numbers = levels.map((e) => e.abs()).join('・');

    return levels.first < 0 ? '地下$numbers階' : '$numbers階';
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
