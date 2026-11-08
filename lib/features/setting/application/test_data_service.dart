import 'dart:convert';
import 'dart:io';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../location/data/models/location_log.dart';
import '../../location/domain/entities/registered_place.dart';
import '../../location/domain/repositories/registered_place_repository.dart';
import '../../share/domain/repositories/share_repository.dart';
import '../domain/services/test_location_generator.dart';
import '../domain/services/test_post_generator.dart';

/// テスト用のXの投稿と行動履歴を、追加・削除する(設定画面の「テストデータ」から使う)
///
/// - 投稿: URLが[TestPostGenerator.urlPrefix]で始まるものが、テスト用
/// - 行動履歴: 滞在する場所は「登録した場所」(名前が[TestLocationGenerator.namePrefix]で始まる)、
///   位置の記録は、目印を付けられないので、保存したIDをファイルに控えて、削除に使う
class TestDataService {
  TestDataService({
    required this.shareRepository,
    required this.registeredPlaceRepository,
    required this.isar,
  });

  final ShareRepository shareRepository;
  final RegisteredPlaceRepository registeredPlaceRepository;
  final Isar isar;

  // ------------------------------------------------------------
  // Xの投稿
  // ------------------------------------------------------------

  Future<int> postCount() async {
    final posts = await shareRepository.findAll();
    return posts.where(TestPostGenerator.isTestPost).length;
  }

  /// すでにあるテスト用の投稿は、重ならないよう入れ替える。追加した件数を返す
  Future<int> addPosts({required DateTime first, required DateTime last}) async {
    await deletePosts();

    final posts = TestPostGenerator.generate(first: first, last: last);
    for (final post in posts) {
      await shareRepository.save(post);
    }

    return posts.length;
  }

  /// 削除した件数を返す
  Future<int> deletePosts() async {
    final targets = (await shareRepository.findAll())
        .where(TestPostGenerator.isTestPost)
        .toList();

    for (final post in targets) {
      await shareRepository.delete(post.id!);
    }

    return targets.length;
  }

  // ------------------------------------------------------------
  // 行動履歴
  // ------------------------------------------------------------

  Future<int> locationCount() async => (await _readIds()).length;

  /// すでにあるテスト用の行動履歴は、重ならないよう入れ替える。追加した位置の記録の件数を返す
  Future<int> addLocations({
    required DateTime first,
    required DateTime last,
  }) async {
    await deleteLocations();

    final data = TestLocationGenerator.generate(first: first, last: last);

    for (final place in data.places) {
      await registeredPlaceRepository.save(
        RegisteredPlace(
          latitude: place.latitude,
          longitude: place.longitude,
          name: place.name,
        ),
      );
    }

    final logs = [
      for (final point in data.points)
        LocationLog()
          ..latitude = point.latitude
          ..longitude = point.longitude
          ..timestamp = point.time,
    ];

    late List<int> ids;
    await isar.writeTxn(() async {
      ids = await isar.locationLogs.putAll(logs);
    });

    await _writeIds(ids);

    return ids.length;
  }

  /// 削除した位置の記録の件数を返す
  Future<int> deleteLocations() async {
    final ids = await _readIds();

    if (ids.isNotEmpty) {
      await isar.writeTxn(() async {
        await isar.locationLogs.deleteAll(ids);
      });
    }

    final places = await registeredPlaceRepository.getAll();
    for (final place in places) {
      if (place.name.startsWith(TestLocationGenerator.namePrefix)) {
        await registeredPlaceRepository.delete(place.id!);
      }
    }

    await _writeIds(const []);

    return ids.length;
  }

  // 位置の記録のIDを控えるファイル
  Future<File> _idsFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/test_location_ids.json');
  }

  Future<List<int>> _readIds() async {
    try {
      final file = await _idsFile();
      if (!await file.exists()) return const [];

      final data = jsonDecode(await file.readAsString());
      final ids = data is Map ? data['ids'] : null;

      return ids is List ? ids.whereType<int>().toList() : const [];
    } catch (_) {
      return const [];
    }
  }

  Future<void> _writeIds(List<int> ids) async {
    final file = await _idsFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode({'ids': ids}));
  }
}
