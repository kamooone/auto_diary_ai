import 'dart:io';
import 'package:auto_diary_ai/core/logging/app_log.dart';
import 'package:auto_diary_ai/features/location/data/repositories/osm_place_search_repository_impl.dart';
import 'package:auto_diary_ai/features/location/domain/repositories/place_search_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// 実際のOverpass APIに問い合わせて、訪れた場所の取得にかかる時間を確かめる
///
/// 通信するため、通常のテストでは実行しない。次のコマンドで実行する:
///   NETWORK_TEST=1 tools/test.sh test/features/location/place_search_real_test.dart
void main() {
  // OpenStreetMap上の座標(松山市)
  const places = <String, Coordinate>{
    'JR松山駅': (latitude: 33.8397656, longitude: 132.7507738),
    '松山市役所': (latitude: 33.8392735, longitude: 132.7653118),
    'エディオン松山本店': (latitude: 33.8445401, longitude: 132.7516827),
  };

  final enabled = Platform.environment['NETWORK_TEST'] == '1';

  test(
    '松山市の3か所をまとめて検索し、所要時間を表示する',
    () async {
      final repository = OsmPlaceSearchRepositoryImpl();
      final stopwatch = Stopwatch()..start();

      final result = await repository.findNearby(places.values.toList());

      // ignore: avoid_print
      print('--- 検索 ${stopwatch.elapsedMilliseconds}ms ---');
      for (var i = 0; i < places.length; i++) {
        final names = result[i]?.map((e) => '${e.name}(${e.distanceMeters.round()}m)');
        // ignore: avoid_print
        print('${places.keys.elementAt(i)}: ${names?.join(' / ') ?? '取得できませんでした'}');
      }
      // ignore: avoid_print
      print(AppLog.entries.value.join('\n'));

      expect(result, hasLength(places.length));
      expect(result.every((e) => e != null), isTrue, reason: '取得できなかった場所があります');
    },
    skip: enabled ? false : 'NETWORK_TEST=1 を付けると実行します',
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
