import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/app_info/install_date_provider.dart';
import '../../../../core/database/isar_provider.dart';
import '../../../diary/application/providers/diary_providers.dart';
import '../../../location/application/providers/location_providers.dart';
import '../../../share/application/providers/share_providers.dart';
import '../../application/test_data_service.dart';
import '../../domain/services/test_diary_generator.dart';
import '../../domain/services/test_location_generator.dart';
import '../../domain/services/test_post_generator.dart';

/// 日記・Xの投稿・行動履歴の、テスト用のデータを追加・削除する画面
///
/// 日記を1つにする機能や、トークンの見積もりを、日記を1件ずつ書かなくても試せるようにする
class TestDiaryPage extends ConsumerStatefulWidget {
  const TestDiaryPage({super.key});

  @override
  ConsumerState<TestDiaryPage> createState() => _TestDiaryPageState();
}

class _TestDiaryPageState extends ConsumerState<TestDiaryPage> {
  var _isWorking = false;
  String? _message;

  int? _postCount;
  int? _locationCount;

  // 2026年1月1日から10月27日まで
  static final _first = DateTime(2026, 1, 1);
  static final _last = DateTime(2026, 10, 27);

  late final _service = TestDataService(
    shareRepository: ref.read(shareRepositoryProvider),
    registeredPlaceRepository: ref.read(registeredPlaceRepositoryProvider),
    isar: ref.read(isarProvider),
  );

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final postCount = await _service.postCount();
    final locationCount = await _service.locationCount();

    if (!mounted) return;
    setState(() {
      _postCount = postCount;
      _locationCount = locationCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    final count = (ref.watch(diariesProvider).valueOrNull ?? const [])
        .where(TestDiaryGenerator.isTestDiary)
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text("テストデータ")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- 日記 ----
          Text("テスト用の日記", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            "日記を1つにする機能を試すための日記を、2026年1月1日から10月27日まで、"
            "1日1件(各400文字前後。仕事・趣味・旅行・家族や友人の出来事が混ざっています)追加します。\n"
            "タイトルが「${TestDiaryGenerator.titlePrefix}」で始まる日記が、テスト用です。",
          ),
          const SizedBox(height: 8),
          Text("今あるテスト用の日記: $count件"),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _isWorking ? null : _add,
            child: const Text("テスト用の日記を追加する"),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _isWorking || count == 0 ? null : _deleteAll,
            child: const Text("テスト用の日記をすべて削除する"),
          ),

          // ---- Xの投稿 ----
          const Divider(height: 40),
          Text("テスト用のXの投稿", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            "同じ期間(2026年1月1日〜10月27日)に、1日0〜3件の投稿を追加します"
            "(平日は仕事、休日は趣味や外出、旅行や特別な日はその日の出来事)。\n"
            "URLが「${TestPostGenerator.urlPrefix}」で始まる投稿が、テスト用です。",
          ),
          const SizedBox(height: 8),
          Text("今あるテスト用の投稿: ${_postCount ?? "-"}件"),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _isWorking ? null : _addPosts,
            child: const Text("テスト用のXの投稿を追加する"),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _isWorking || (_postCount ?? 0) == 0 ? null : _deletePosts,
            child: const Text("テスト用のXの投稿をすべて削除する"),
          ),

          // ---- 行動履歴 ----
          const Divider(height: 40),
          Text("テスト用の行動履歴", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            "同じ期間のうち、5日おきの日と、旅行の日(京都・海辺の町)、特別な日だけ、"
            "位置の記録を追加します(約60日分)。平日は自宅→職場→自宅、休日は外出です。\n"
            "訪れた場所は、名前が「${TestLocationGenerator.namePrefix}」で始まる「登録した場所」になります"
            "(ネットで調べないので、すぐ表示されます)。削除すると、登録した場所も消えます。",
          ),
          const SizedBox(height: 8),
          Text("今あるテスト用の位置の記録: ${_locationCount ?? "-"}件"),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _isWorking ? null : _addLocations,
            child: const Text("テスト用の行動履歴を追加する"),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _isWorking || (_locationCount ?? 0) == 0
                ? null
                : _deleteLocations,
            child: const Text("テスト用の行動履歴をすべて削除する"),
          ),

          if (_isWorking) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
          if (_message != null) ...[
            const SizedBox(height: 16),
            Text(_message!),
          ],
        ],
      ),
    );
  }

  // すでにあるテスト用の日記は、重ならないよう入れ替える
  Future<void> _add() async {
    await _run(() async {
      await _deleteTestDiaries();

      final save = ref.read(saveDiaryUseCaseProvider);
      final diaries = TestDiaryGenerator.generate(first: _first, last: _last);
      for (final diary in diaries) {
        await save.execute(diary);
      }

      return "${diaries.length}件を追加しました";
    });
  }

  Future<void> _deleteAll() async {
    await _run(() async {
      final count = await _deleteTestDiaries();
      return "$count件を削除しました";
    });
  }

  Future<int> _deleteTestDiaries() async {
    final diaries = await ref.read(diariesProvider.future);
    final targets = diaries.where(TestDiaryGenerator.isTestDiary).toList();

    final delete = ref.read(deleteDiaryUseCaseProvider);
    for (final diary in targets) {
      await delete.execute(diary.id!);
    }

    return targets.length;
  }

  Future<void> _addPosts() async {
    await _run(() async {
      final count = await _service.addPosts(first: _first, last: _last);
      ref.invalidate(allSharedPostsProvider);
      return "投稿を$count件追加しました";
    });
  }

  Future<void> _deletePosts() async {
    await _run(() async {
      final count = await _service.deletePosts();
      ref.invalidate(allSharedPostsProvider);
      return "投稿を$count件削除しました";
    });
  }

  Future<void> _addLocations() async {
    await _run(() async {
      final count = await _service.addLocations(first: _first, last: _last);
      return "位置の記録を$count件と、登録した場所を追加しました";
    });
  }

  Future<void> _deleteLocations() async {
    await _run(() async {
      final count = await _service.deleteLocations();
      return "位置の記録を$count件と、登録した場所を削除しました";
    });
  }

  // テスト用のデータの日付を、日記の作成画面などで選べるよう、使い始めた日を早める
  Future<void> _allowSelecting() {
    return moveInstallDateEarlier(
      ref.read(isarProvider),
      ref.read(installDateProvider.notifier),
      _first,
    );
  }

  Future<void> _run(Future<String> Function() task) async {
    setState(() {
      _isWorking = true;
      _message = null;
    });

    String message;
    try {
      message = await task();
      await _allowSelecting();
    } catch (e) {
      message = "失敗しました: $e";
    }

    await _loadCounts();

    if (!mounted) return;
    setState(() {
      _isWorking = false;
      _message = message;
    });
  }
}
