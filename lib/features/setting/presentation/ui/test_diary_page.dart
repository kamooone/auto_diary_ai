import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../diary/application/providers/diary_providers.dart';
import '../../domain/services/test_diary_generator.dart';

/// まとめ日記を試すための、テスト用の日記を追加・削除する画面
class TestDiaryPage extends ConsumerStatefulWidget {
  const TestDiaryPage({super.key});

  @override
  ConsumerState<TestDiaryPage> createState() => _TestDiaryPageState();
}

class _TestDiaryPageState extends ConsumerState<TestDiaryPage> {
  var _isWorking = false;
  String? _message;

  // 2026年1月1日から10月27日まで
  static final _first = DateTime(2026, 1, 1);
  static final _last = DateTime(2026, 10, 27);

  @override
  Widget build(BuildContext context) {
    final count = (ref.watch(diariesProvider).valueOrNull ?? const [])
        .where(TestDiaryGenerator.isTestDiary)
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text("テスト用の日記")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "まとめ日記を試すための日記を、2026年1月1日から10月27日まで、"
            "1日1件(各500文字前後)追加します。\n"
            "タイトルが「${TestDiaryGenerator.titlePrefix}」で始まる日記が、テスト用です。",
          ),
          const SizedBox(height: 16),
          Text("今あるテスト用の日記: $count件"),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isWorking ? null : _add,
            child: const Text("テスト用の日記を追加する"),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _isWorking || count == 0 ? null : _deleteAll,
            child: const Text("テスト用の日記をすべて削除する"),
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

  Future<void> _run(Future<String> Function() task) async {
    setState(() {
      _isWorking = true;
      _message = null;
    });

    String message;
    try {
      message = await task();
    } catch (e) {
      message = "失敗しました: $e";
    }

    if (!mounted) return;
    setState(() {
      _isWorking = false;
      _message = message;
    });
  }
}
