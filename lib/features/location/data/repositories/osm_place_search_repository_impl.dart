import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../../domain/entities/place_candidate.dart';
import '../../domain/exceptions/place_search_exception.dart';
import '../../domain/repositories/place_search_repository.dart';
import '../datasources/place_candidate_cache.dart';

/// OpenStreetMap(Overpass API)で周辺の施設を検索する
class OsmPlaceSearchRepositoryImpl implements PlaceSearchRepository {
  final http.Client _client;

  // 同じ場所を何度も問い合わせないよう、検索結果を保存して再利用する
  final PlaceCandidateCache _cache;

  OsmPlaceSearchRepositoryImpl({
    http.Client? client,
    PlaceCandidateCache? cache,
  })  : _client = client ?? http.Client(),
        _cache = cache ?? MemoryPlaceCandidateCache();

  static final _endpoint = Uri.parse('https://overpass-api.de/api/interpreter');

  // 公開サーバーの利用条件として、アプリを識別できる情報を送る
  static const _userAgent = 'auto_diary_ai/1.0';

  static const _timeout = Duration(seconds: 12);

  // 滞在場所からこの距離以内にある施設を候補にする
  static const _radiusMeters = 75;

  // 1か所あたりの候補の上限
  static const _maxCandidates = 8;

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
  Future<List<List<PlaceCandidate>>> findNearby(
    List<Coordinate> coordinates,
  ) async {
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

    if (missing.isNotEmpty) {
      final List<Map<String, dynamic>> elements;

      try {
        // 問い合わせは1回にまとめる
        elements = await _fetch(missing);
      } catch (e) {
        throw PlaceSearchException('施設の候補を取得できませんでした: $e');
      }

      for (final coordinate in missing) {
        final key = _key(coordinate);
        final candidates = _candidates(coordinate, elements);

        results[key] = candidates;
        await _cache.put(key, candidates);
      }
    }

    return [
      for (final coordinate in coordinates) results[_key(coordinate)] ?? const [],
    ];
  }

  // 小数第4位(約10m)で丸めた座標をキーにする
  String _key(Coordinate coordinate) {
    return '${coordinate.latitude.toStringAsFixed(4)},'
        '${coordinate.longitude.toStringAsFixed(4)}';
  }

  Future<List<Map<String, dynamic>>> _fetch(List<Coordinate> coordinates) async {
    final statements = StringBuffer();

    for (final coordinate in coordinates) {
      final around =
          'around:$_radiusMeters,${coordinate.latitude},${coordinate.longitude}';

      statements
        ..writeln(
          'nwr($around)[name][~"^(amenity|shop|tourism|leisure|office)\$"~"."];',
        )
        ..writeln('nwr($around)[name][railway~"^(station|halt)\$"];');
    }

    final query = '[out:json][timeout:10];($statements);out center tags 300;';

    final response = await _client.post(
      _endpoint,
      headers: {'User-Agent': _userAgent},
      body: {'data': query},
    ).timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('Overpass API: ${response.statusCode}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final elements = data is Map<String, dynamic> ? data['elements'] : null;

    return [
      if (elements is List)
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
