import 'package:auto_diary_ai/features/diary_create/domain/services/photo_period_filter.dart';
import 'package:auto_diary_ai/features/memo/application/providers/memo_providers.dart';
import 'package:auto_diary_ai/features/memo/domain/entities/memo.dart';
import 'package:auto_diary_ai/features/memo/domain/repositories/memo_repository.dart';
import 'package:auto_diary_ai/features/memo/domain/services/memo_filter.dart';
import 'package:auto_diary_ai/features/memo/presentation/ui/memo_edit_dialog.dart';
import 'package:auto_diary_ai/features/memo/presentation/ui/memo_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryMemoRepository implements MemoRepository {
  final items = <Memo>[];
  var _nextId = 1;

  @override
  Future<void> save(Memo memo) async {
    items.add(
      Memo(
        id: _nextId++,
        text: memo.text,
        createdAt: memo.createdAt,
        photoIds: memo.photoIds,
      ),
    );
  }

  @override
  Future<void> update(Memo memo) async {
    final index = items.indexWhere((e) => e.id == memo.id);
    items[index] = memo;
  }

  @override
  Future<void> delete(int id) async => items.removeWhere((e) => e.id == id);

  @override
  Future<List<Memo>> findAll() async =>
      [...items]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<List<Memo>> findBetween(DateTime start, DateTime end) async => [
    for (final e in items)
      if (!e.createdAt.isBefore(start) && e.createdAt.isBefore(end)) e,
  ];
}

Memo memo(String text, DateTime at, {int? id}) =>
    Memo(id: id, text: text, createdAt: at);

void main() {
  late MemoryMemoRepository repository;

  setUp(() => repository = MemoryMemoRepository());

  Widget app() => ProviderScope(
    overrides: [memoRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(
      home: Scaffold(
        body: Consumer(
          builder: (context, ref, _) => Column(
            children: [
              const Expanded(child: MemoListView()),
              TextButton(
                onPressed: () => showMemoEditDialog(context),
                child: const Text('追加ボタン'),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  group('一覧', () {
    testWidgets('メモがないときは、案内を出す', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(find.textContaining('まだひとことメモがありません'), findsOneWidget);
    });

    testWidgets('新しい順に並び、日時と本文が出る', (tester) async {
      await repository.save(memo('古いメモ', DateTime(2026, 11, 1, 9, 5)));
      await repository.save(memo('新しいメモ', DateTime(2026, 11, 9, 12, 34)));

      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(find.text('2026年11月9日（月） 12:34'), findsOneWidget);
      expect(find.text('2026年11月1日（日） 9:05'), findsOneWidget);

      final newer = tester.getTopLeft(find.text('新しいメモ')).dy;
      final older = tester.getTopLeft(find.text('古いメモ')).dy;
      expect(newer, lessThan(older));
    });

    testWidgets('削除は、確認してから消える', (tester) async {
      await repository.save(memo('消すメモ', DateTime(2026, 11, 9, 12, 0)));

      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('メニュー'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('削除'));
      await tester.pumpAndSettle();

      // キャンセルすると、消えない
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      expect(find.text('消すメモ'), findsOneWidget);

      await tester.tap(find.byTooltip('メニュー'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('削除'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('削除する'));
      await tester.pumpAndSettle();

      expect(find.text('消すメモ'), findsNothing);
      expect(repository.items, isEmpty);
    });
  });

  group('年・月と検索の絞り込み', () {
    Future<void> setUpThree(WidgetTester tester) async {
      await repository.save(memo('海に行った', DateTime(2025, 8, 3, 10)));
      await repository.save(memo('山に行った', DateTime(2026, 8, 5, 10)));
      await repository.save(memo('海は青かった', DateTime(2026, 9, 1, 10)));

      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
    }

    testWidgets('初めは、すべてのメモが出る', (tester) async {
      await setUpThree(tester);

      expect(find.text('海に行った'), findsOneWidget);
      expect(find.text('山に行った'), findsOneWidget);
      expect(find.text('海は青かった'), findsOneWidget);
    });

    testWidgets('検索すると、その言葉を含むメモだけになる', (tester) async {
      await setUpThree(tester);

      await tester.enterText(find.byKey(const Key('memoSearch')), '海');
      await tester.pumpAndSettle();

      expect(find.text('海に行った'), findsOneWidget);
      expect(find.text('海は青かった'), findsOneWidget);
      expect(find.text('山に行った'), findsNothing);
    });

    testWidgets('年を選ぶと、その年のメモだけになり、検索と同時に使える', (tester) async {
      await setUpThree(tester);

      await tester.tap(find.byKey(const Key('photoYear')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2026年').last);
      await tester.pumpAndSettle();

      expect(find.text('海に行った'), findsNothing);
      expect(find.text('山に行った'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('memoSearch')), '海');
      await tester.pumpAndSettle();

      expect(find.text('海は青かった'), findsOneWidget);
      expect(find.text('山に行った'), findsNothing);
    });

    testWidgets('合うメモがないときは、案内を出す', (tester) async {
      await setUpThree(tester);

      await tester.enterText(find.byKey(const Key('memoSearch')), '空');
      await tester.pumpAndSettle();

      expect(find.text('条件に合うメモがありません'), findsOneWidget);
    });
  });

  group('MemoFilter', () {
    final memos = [
      memo('Coffee と 読書', DateTime(2026, 8, 31, 23, 59)),
      memo('読書だけ', DateTime(2026, 9, 1)),
    ];

    test('年・月は、月の初めから終わりまでを含む', () {
      final august = MemoFilter.apply(
        memos,
        period: const PhotoPeriodFilter(year: 2026, month: 8),
      );

      expect(august.map((e) => e.text), ['Coffee と 読書']);
    });

    test('空白で区切ると、すべての言葉を含むものを探す(大文字・小文字は区別しない)', () {
      expect(MemoFilter.apply(memos, query: 'coffee\u3000読書').length, 1);
      expect(MemoFilter.apply(memos, query: '読書').length, 2);
      expect(MemoFilter.apply(memos, query: '  ').length, 2);
    });

    test('年の選択肢は、メモのある年だけ(新しい年が先頭)', () {
      expect(
        MemoFilter.years([
          memo('a', DateTime(2024, 1, 1)),
          memo('b', DateTime(2026, 1, 1)),
          memo('c', DateTime(2024, 5, 1)),
        ]),
        [2026, 2024],
      );
    });
  });

  group('追加・修正のダイアログ', () {
    testWidgets('本文を書くまでは、追加できない', (tester) async {
      await tester.pumpWidget(app());
      await tester.tap(find.text('追加ボタン'));
      await tester.pumpAndSettle();

      FilledButton button() =>
          tester.widget<FilledButton>(find.widgetWithText(FilledButton, '追加'));
      expect(button().onPressed, isNull);

      await tester.enterText(find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField)), '   ');
      await tester.pump();
      expect(button().onPressed, isNull);

      await tester.enterText(find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField)), '散歩した');
      await tester.pump();
      expect(button().onPressed, isNotNull);
    });

    testWidgets('追加すると、一覧に出て、保存される(前後の空白は取る)', (tester) async {
      await tester.pumpWidget(app());
      await tester.tap(find.text('追加ボタン'));
      await tester.pumpAndSettle();

      await tester.enterText(find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField)), '  散歩した  ');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, '追加'));
      await tester.pumpAndSettle();

      expect(find.text('散歩した'), findsOneWidget);
      expect(repository.items.single.text, '散歩した');
      expect(repository.items.single.photoIds, isEmpty);
    });

    testWidgets('本文は、280文字までしか入力できない', (tester) async {
      await tester.pumpWidget(app());
      await tester.tap(find.text('追加ボタン'));
      await tester.pumpAndSettle();

      await tester.enterText(find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField)), 'あ' * 300);
      await tester.pump();

      final field = tester.widget<TextField>(find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField)));
      expect(field.controller!.text.length, Memo.maxLength);
    });

    testWidgets('修正すると、同じメモが更新される(日時は変えない)', (tester) async {
      final at = DateTime(2026, 11, 9, 12, 34);
      await repository.save(memo('はじめの文', at));

      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.tap(find.text('はじめの文'));
      await tester.pumpAndSettle();

      expect(find.text('ひとことメモを修正'), findsOneWidget);
      await tester.enterText(find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField)), '直した文');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, '保存'));
      await tester.pumpAndSettle();

      expect(repository.items, hasLength(1));
      expect(repository.items.single.text, '直した文');
      expect(repository.items.single.createdAt, at);
      expect(find.text('直した文'), findsOneWidget);
    });

    testWidgets('キャンセルすると、保存しない', (tester) async {
      await tester.pumpWidget(app());
      await tester.tap(find.text('追加ボタン'));
      await tester.pumpAndSettle();

      await tester.enterText(find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField)), '書きかけ');
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(repository.items, isEmpty);
    });
  });
}
