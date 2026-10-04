import 'dart:convert';
import 'package:auto_diary_ai/features/location/data/repositories/osm_place_search_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const tokyoStation = (latitude: 35.681236, longitude: 139.767125);

  http.Response json(Object body) {
    return http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      200,
      headers: {'content-type': 'application/json'},
    );
  }

  test('近い順に候補を返し、種類を日本語にする', () async {
    final repository = OsmPlaceSearchRepositoryImpl(
      client: MockClient((request) async {
        return json({
          'elements': [
            {
              'type': 'way',
              'center': {'lat': 35.6816, 'lon': 139.7671},
              'tags': {'name': '東京駅一番街', 'shop': 'mall'},
            },
            {
              'type': 'node',
              'lat': 35.68124,
              'lon': 139.76713,
              'tags': {'name': '東京', 'railway': 'station'},
            },
          ],
        });
      }),
    );

    final result = await repository.findNearby([tokyoStation]);

    expect(result, hasLength(1));
    expect(result.single.map((e) => e.name), ['東京駅', '東京駅一番街']);
    expect(result.single.first.category, '駅');
    expect(result.single.last.category, 'ショッピングモール');
  });

  test('範囲外・名前なし・駐車場などは候補にしない', () async {
    final repository = OsmPlaceSearchRepositoryImpl(
      client: MockClient((request) async {
        return json({
          'elements': [
            {
              'type': 'node',
              'lat': 35.69,
              'lon': 139.7671,
              'tags': {'name': '遠い店', 'shop': 'books'},
            },
            {
              'type': 'node',
              'lat': 35.68124,
              'lon': 139.76713,
              'tags': {'amenity': 'cafe'},
            },
            {
              'type': 'node',
              'lat': 35.68124,
              'lon': 139.76713,
              'tags': {'name': '第一駐車場', 'amenity': 'parking'},
            },
          ],
        });
      }),
    );

    final result = await repository.findNearby([tokyoStation]);

    expect(result.single, isEmpty);
  });

  test('同じ名前の施設は1つにまとめる', () async {
    final repository = OsmPlaceSearchRepositoryImpl(
      client: MockClient((request) async {
        return json({
          'elements': [
            for (var i = 0; i < 2; i++)
              {
                'type': 'node',
                'lat': 35.68124,
                'lon': 139.76713,
                'tags': {'name': 'カフェA', 'amenity': 'cafe'},
              },
          ],
        });
      }),
    );

    final result = await repository.findNearby([tokyoStation]);

    expect(result.single.map((e) => e.name), ['カフェA']);
  });

  test('複数の場所を1回の問い合わせで取得し、結果を再利用する', () async {
    var requestCount = 0;

    final repository = OsmPlaceSearchRepositoryImpl(
      client: MockClient((request) async {
        requestCount++;
        return json({
          'elements': [
            {
              'type': 'node',
              'lat': 35.68124,
              'lon': 139.76713,
              'tags': {'name': 'カフェA', 'amenity': 'cafe'},
            },
            {
              'type': 'node',
              'lat': 35.0001,
              'lon': 135.0001,
              'tags': {'name': 'カフェB', 'amenity': 'cafe'},
            },
          ],
        });
      }),
    );

    const other = (latitude: 35.0, longitude: 135.0);

    final result = await repository.findNearby([tokyoStation, other]);
    await repository.findNearby([tokyoStation, other]);

    expect(result[0].map((e) => e.name), ['カフェA']);
    expect(result[1].map((e) => e.name), ['カフェB']);
    expect(requestCount, 1);
  });

  test('取得に失敗した場合は空の候補を返す', () async {
    final repository = OsmPlaceSearchRepositoryImpl(
      client: MockClient((request) async => http.Response('error', 429)),
    );

    final result = await repository.findNearby([tokyoStation]);

    expect(result.single, isEmpty);
  });
}
