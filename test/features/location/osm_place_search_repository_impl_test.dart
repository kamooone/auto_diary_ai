import 'dart:convert';
import 'package:auto_diary_ai/features/location/data/repositories/osm_place_search_repository_impl.dart';
import 'package:auto_diary_ai/features/location/domain/exceptions/place_search_exception.dart';
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
    expect(result.single!.map((e) => e.name), ['東京駅', '東京駅一番街']);
    expect(result.single!.first.category, '駅');
    expect(result.single!.last.category, 'ショッピングモール');
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

    expect(result.single!.map((e) => e.name), ['カフェA']);
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

    expect(result[0]!.map((e) => e.name), ['カフェA']);
    expect(result[1]!.map((e) => e.name), ['カフェB']);
    expect(requestCount, 1);
  });

  test('取得に失敗した場合はnullを返し、結果を保存しない', () async {
    var shouldFail = true;

    final repository = OsmPlaceSearchRepositoryImpl(
      client: MockClient((request) async {
        if (shouldFail) return http.Response('error', 429);

        return json({
          'elements': [
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

    expect(await repository.findNearby([tokyoStation]), [null]);

    // 失敗した結果は保存されないため、次の問い合わせで取得できる
    shouldFail = false;
    final result = await repository.findNearby([tokyoStation]);

    expect(result.single!.map((e) => e.name), ['カフェA']);
  });

  test('検索が打ち切られた場合は失敗として扱い、結果を保存しない', () async {
    var isInterrupted = true;

    final repository = OsmPlaceSearchRepositoryImpl(
      client: MockClient((request) async {
        // 時間切れのときは、200のまま空の結果とremarkが返る
        if (isInterrupted) {
          return json({
            'elements': [],
            'remark': 'runtime error: Query timed out in "query" at line 1',
          });
        }

        return json({
          'elements': [
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

    expect(await repository.findNearby([tokyoStation]), [null]);

    // 「周辺に施設がない」とは保存されないため、次の問い合わせで取得できる
    isInterrupted = false;
    final result = await repository.findNearby([tokyoStation]);

    expect(result.single!.map((e) => e.name), ['カフェA']);
  });

  test('応答に施設の一覧がない場合は失敗として扱う', () async {
    final repository = OsmPlaceSearchRepositoryImpl(
      client: MockClient((request) async => json({'version': 0.6})),
    );

    expect(await repository.findNearby([tokyoStation]), [null]);
  });

  test('結果が上限に達した場合は、場所を分けて取り直す', () async {
    const other = (latitude: 35.0, longitude: 135.0);

    Map<String, dynamic> cafe(String name, double lat, double lon) {
      return {
        'type': 'node',
        'lat': lat,
        'lon': lon,
        'tags': {'name': name, 'amenity': 'cafe'},
      };
    }

    var requestCount = 0;

    final repository = OsmPlaceSearchRepositoryImpl(
      client: MockClient((request) async {
        requestCount++;

        final query = request.bodyFields['data']!;
        final hasTokyo = query.contains('${tokyoStation.latitude}');
        final hasOther = query.contains('${other.latitude},${other.longitude}');

        // 2か所まとめた問い合わせは、東京駅の施設だけで上限に達する
        if (hasTokyo && hasOther) {
          return json({
            'elements': [
              for (var i = 0; i < 300; i++) cafe('カフェ$i', 35.68124, 139.76713),
            ],
          });
        }

        return json({
          'elements': [
            if (hasTokyo) cafe('カフェA', 35.68124, 139.76713),
            if (hasOther) cafe('カフェB', 35.0001, 135.0001),
          ],
        });
      }),
    );

    final result = await repository.findNearby([tokyoStation, other]);

    expect(result[0]!.map((e) => e.name), ['カフェA']);
    expect(result[1]!.map((e) => e.name), ['カフェB']);
    expect(requestCount, 3);
  });

  test('まとめた検索が打ち切られた場合は、場所を分けて取り直し、取得できた場所だけ返す', () async {
    const heavy = (latitude: 35.0, longitude: 135.0);
    const other = (latitude: 34.0, longitude: 134.0);

    var isHeavyInterrupted = true;
    final queries = <String>[];

    final repository = OsmPlaceSearchRepositoryImpl(
      client: MockClient((request) async {
        final query = request.bodyFields['data']!;
        queries.add(query);

        // heavyを含む問い合わせは、時間切れで打ち切られる
        if (isHeavyInterrupted && query.contains('${heavy.latitude},')) {
          return json({
            'elements': [],
            'remark': 'runtime error: Query timed out in "query" at line 1',
          });
        }

        return json({
          'elements': [
            if (query.contains('${tokyoStation.latitude}'))
              {
                'type': 'node',
                'lat': 35.68124,
                'lon': 139.76713,
                'tags': {'name': 'カフェA', 'amenity': 'cafe'},
              },
            if (query.contains('${heavy.latitude},'))
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

    final result = await repository.findNearby([tokyoStation, heavy, other]);

    expect(result[0]!.map((e) => e.name), ['カフェA']);
    expect(result[1], isNull);
    expect(result[2], isEmpty);

    // 取得できた場所は保存されているため、次は取得できなかった場所だけを問い合わせる
    isHeavyInterrupted = false;
    queries.clear();

    final retried = await repository.findNearby([tokyoStation, heavy, other]);

    expect(retried[1]!.map((e) => e.name), ['カフェB']);
    expect(queries, hasLength(1));
    expect(queries.single, isNot(contains('${tokyoStation.latitude}')));
  });

  test('通信できない場合は、場所を分けて取り直さない', () async {
    const other = (latitude: 35.0, longitude: 135.0);

    var requestCount = 0;

    final repository = OsmPlaceSearchRepositoryImpl(
      endpoints: [Uri.parse('https://first.example/api')],
      client: MockClient((request) async {
        requestCount++;
        throw http.ClientException('offline');
      }),
    );

    expect(await repository.findNearby([tokyoStation, other]), [null, null]);
    expect(requestCount, 1);
  });

  test('動作確認用の検索は、保存した結果を使わず、失敗の理由を伝える', () async {
    var shouldFail = false;
    var requestCount = 0;

    final repository = OsmPlaceSearchRepositoryImpl(
      client: MockClient((request) async {
        requestCount++;
        if (shouldFail) return http.Response('error', 429);

        return json({
          'elements': [
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

    await repository.findNearby([tokyoStation]);
    final result = await repository.search(tokyoStation);

    expect(result.map((e) => e.name), ['カフェA']);
    expect(requestCount, 2);

    shouldFail = true;

    await expectLater(
      repository.search(tokyoStation),
      throwsA(
        isA<PlaceSearchException>()
            .having((e) => e.message, 'message', contains('429')),
      ),
    );
  });

  test('施設の種類を指定して検索し、正規表現でキーを指定しない', () async {
    String? query;

    final repository = OsmPlaceSearchRepositoryImpl(
      client: MockClient((request) async {
        query = request.bodyFields['data'];
        return json({'elements': []});
      }),
    );

    await repository.findNearby([tokyoStation]);

    expect(query, contains('[name][amenity];'));
    expect(query, contains('[name][shop];'));
    expect(query, contains('[name][railway~'));
    expect(query, isNot(contains('~"^(amenity')));
  });

  test('応答がないサーバーは飛ばして、次のサーバーで取得する', () async {
    final hosts = <String>[];

    final repository = OsmPlaceSearchRepositoryImpl(
      endpoints: [
        Uri.parse('https://first.example/api'),
        Uri.parse('https://second.example/api'),
      ],
      client: MockClient((request) async {
        hosts.add(request.url.host);
        if (request.url.host == 'first.example') {
          return http.Response('busy', 429);
        }

        return json({
          'elements': [
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

    expect(hosts, ['first.example', 'second.example']);
    expect(result.single!.map((e) => e.name), ['カフェA']);
  });

  test('どのサーバーも応答がない場合はnullを返す', () async {
    var requestCount = 0;

    final repository = OsmPlaceSearchRepositoryImpl(
      endpoints: [
        Uri.parse('https://first.example/api'),
        Uri.parse('https://second.example/api'),
      ],
      client: MockClient((request) async {
        requestCount++;
        return http.Response('error', 500);
      }),
    );

    expect(await repository.findNearby([tokyoStation]), [null]);
    expect(requestCount, 2);
  });

  test('複数の場所をまとめた検索がどのサーバーでも処理しきれなかった場合は、分けて取り直す', () async {
    const other = (latitude: 35.0, longitude: 135.0);
    final requests = <int>[];

    final repository = OsmPlaceSearchRepositoryImpl(
      endpoints: [
        Uri.parse('https://first.example/api'),
        Uri.parse('https://second.example/api'),
      ],
      client: MockClient((request) async {
        // 2か所をまとめた問い合わせだけ504になる
        final count = RegExp('around:').allMatches(request.bodyFields['data']!).length;
        requests.add(count);
        if (count > 6) return http.Response('timeout', 504);

        return json({'elements': []});
      }),
    );

    final result = await repository.findNearby([tokyoStation, other]);

    expect(result, [isEmpty, isEmpty]);
    // まとめた問い合わせは両方のサーバーで処理しきれず、1か所ずつ取り直す
    expect(requests.first, 12);
    expect(requests.where((e) => e == 12), hasLength(2));
    expect(requests.where((e) => e == 6), hasLength(2));
  });

  test('多くの場所は2か所ずつに分け、サーバーを振り分けて取得する', () async {
    final requests = <({String host, int count})>[];

    final repository = OsmPlaceSearchRepositoryImpl(
      endpoints: [
        Uri.parse('https://first.example/api'),
        Uri.parse('https://second.example/api'),
      ],
      client: MockClient((request) async {
        final count =
            RegExp('around:').allMatches(request.bodyFields['data']!).length ~/ 6;
        requests.add((host: request.url.host, count: count));
        return json({'elements': []});
      }),
    );

    final result = await repository.findNearby([
      for (var i = 0; i < 5; i++) (latitude: 35.0 + i, longitude: 135.0),
    ]);

    expect(result, everyElement(isEmpty));
    expect(requests.map((e) => e.count).toList()..sort(), [1, 2, 2]);
    expect(requests.map((e) => e.host).toSet(), {'first.example', 'second.example'});
  });

  test('応答が遅くて待ちきれなかった場合は、場所を分けて取り直す', () async {
    const other = (latitude: 35.0, longitude: 135.0);
    final counts = <int>[];

    final repository = OsmPlaceSearchRepositoryImpl(
      timeout: const Duration(milliseconds: 50),
      endpoints: [Uri.parse('https://first.example/api')],
      client: MockClient((request) async {
        final count =
            RegExp('around:').allMatches(request.bodyFields['data']!).length ~/ 6;
        counts.add(count);

        // 2か所をまとめた問い合わせだけが遅い
        if (count > 1) await Future<void>.delayed(const Duration(milliseconds: 300));
        return json({'elements': []});
      }),
    );

    final result = await repository.findNearby([tokyoStation, other]);

    expect(result, [isEmpty, isEmpty]);
    expect(counts, [2, 1, 1]);
  });

  test('応答が遅いサーバーは待たずに、次のサーバーの結果を使う', () async {
    final hosts = <String>[];
    final stopwatch = Stopwatch()..start();

    final repository = OsmPlaceSearchRepositoryImpl(
      hedgeDelay: const Duration(milliseconds: 50),
      endpoints: [
        Uri.parse('https://slow.example/api'),
        Uri.parse('https://fast.example/api'),
      ],
      client: MockClient((request) async {
        hosts.add(request.url.host);
        if (request.url.host == 'slow.example') {
          await Future<void>.delayed(const Duration(seconds: 2));
        }

        return json({
          'elements': [
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

    expect(hosts, ['slow.example', 'fast.example']);
    expect(result.single!.map((e) => e.name), ['カフェA']);
    expect(stopwatch.elapsedMilliseconds, lessThan(1000));
  });

  test('失敗したサーバーは、次の問い合わせから後回しにする', () async {
    final hosts = <String>[];

    final repository = OsmPlaceSearchRepositoryImpl(
      endpoints: [
        Uri.parse('https://bad.example/api'),
        Uri.parse('https://good.example/api'),
      ],
      client: MockClient((request) async {
        hosts.add(request.url.host);
        if (request.url.host == 'bad.example') {
          return http.Response('error', 500);
        }

        return json({'elements': []});
      }),
    );

    await repository.findNearby([tokyoStation]);
    hosts.clear();
    await repository.findNearby([(latitude: 35.0, longitude: 135.0)]);

    expect(hosts, ['good.example']);
  });
}
