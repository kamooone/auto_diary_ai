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

// 今月・先月の、日時(月ごとの表示で、今月が先に開くため、いつ実行しても通るようにする)
final _now = DateTime.now();
DateTime thisMonth(int day, [int hour = 9, int minute = 0]) =>
    DateTime(_now.year, _now.month, day, hour, minute);
DateTime lastMonth(int day, [int hour = 9]) =>
    DateTime(_now.year, _now.month - 1, day, hour);

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
      await repository.save(memo('古いメモ', thisMonth(1, 9, 5)));
      await repository.save(memo('新しいメモ', thisMonth(2, 12, 34)));

      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      // 月の見出しと、日付(左の列)、時刻(カードの中)が出る
      expect(find.text('${_now.year}年${_now.month}月'), findsOneWidget);
      expect(find.text('12:34'), findsOneWidget);
      expect(find.text('9:05'), findsOneWidget);

      final newer = tester.getTopLeft(find.text('新しいメモ')).dy;
      final older = tester.getTopLeft(find.text('古いメモ')).dy;
      expect(newer, lessThan(older));
    });

    testWidgets('削除は、確認してから消える', (tester) async {
      await repository.save(memo('消すメモ', thisMonth(2, 12, 0)));

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

  group('月の切り替えと検索', () {
    Future<void> setUpThree(WidgetTester tester) async {
      await repository.save(memo('今月の海', thisMonth(2, 10)));
      await repository.save(memo('先月の山', lastMonth(5, 10)));
      await repository.save(memo('先月の海は青かった', lastMonth(1, 10)));

      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
    }

    testWidgets('初めは、今月のメモだけが出る', (tester) async {
      await setUpThree(tester);

      expect(find.text('今月の海'), findsOneWidget);
      expect(find.text('先月の山'), findsNothing);
    });

    testWidgets('前の月のボタンで、先月のメモが出る。次の月のボタンで、今月に戻る', (tester) async {
      await setUpThree(tester);

      await tester.tap(find.byKey(const Key('homePreviousMonth')));
      await tester.pumpAndSettle();

      expect(find.text('先月の山'), findsOneWidget);
      expect(find.text('先月の海は青かった'), findsOneWidget);
      expect(find.text('今月の海'), findsNothing);

      await tester.tap(find.byKey(const Key('homeNextMonth')));
      await tester.pumpAndSettle();

      expect(find.text('今月の海'), findsOneWidget);
    });

    testWidgets('年月を押して出るシートで、月を選べる', (tester) async {
      await setUpThree(tester);

      await tester.tap(find.byKey(const Key('homeMonthLabel')));
      await tester.pumpAndSettle();

      final last = DateTime(_now.year, _now.month - 1);
      final key = '${last.year}-${last.month.toString().padLeft(2, '0')}';
      await tester.tap(find.byKey(Key('sheetMonth-$key')));
      await tester.pumpAndSettle();

      expect(find.text('先月の山'), findsOneWidget);
    });

    testWidgets('検索すると、すべての月から、その言葉を含むメモが出る(月の切り替えは隠れる)', (tester) async {
      await setUpThree(tester);

      await tester.enterText(find.byKey(const Key('memoSearch')), '海');
      await tester.pumpAndSettle();

      expect(find.text('今月の海'), findsOneWidget);
      expect(find.text('先月の海は青かった'), findsOneWidget);
      expect(find.text('先月の山'), findsNothing);
      expect(find.byKey(const Key('homeMonthLabel')), findsNothing);
    });

    testWidgets('検索を消すと、月の切り替えが戻る', (tester) async {
      await setUpThree(tester);

      await tester.enterText(find.byKey(const Key('memoSearch')), '海');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('memoSearch')), '');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('homeMonthLabel')), findsOneWidget);
      expect(find.text('今月の海'), findsOneWidget);
    });

    testWidgets('合うメモがないときは、案内を出す', (tester) async {
      await setUpThree(tester);

      await tester.enterText(find.byKey(const Key('memoSearch')), '空');
      await tester.pumpAndSettle();

      expect(find.text('条件に合うメモがありません'), findsOneWidget);
    });

    testWidgets('その月にメモがないときは、案内を出す', (tester) async {
      await repository.save(memo('先月だけ', lastMonth(5, 10)));

      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(find.textContaining('この月は、まだひとことがありません'), findsOneWidget);
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

      // 押せないときは、タップしても、何も起きない
      InkWell button() => tester.widget<InkWell>(
        find.ancestor(of: find.text('追加する'), matching: find.byType(InkWell)),
      );
      expect(button().onTap, isNull);

      await tester.enterText(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(TextField),
        ),
        '   ',
      );
      await tester.pump();
      expect(button().onTap, isNull);

      await tester.enterText(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(TextField),
        ),
        '散歩した',
      );
      await tester.pump();
      expect(button().onTap, isNotNull);
    });

    testWidgets('追加すると、一覧に出て、保存される(前後の空白は取る)', (tester) async {
      await tester.pumpWidget(app());
      await tester.tap(find.text('追加ボタン'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(TextField),
        ),
        '  散歩した  ',
      );
      await tester.pump();
      await tester.tap(find.text('追加する'));
      await tester.pumpAndSettle();

      expect(find.text('散歩した'), findsOneWidget);
      expect(repository.items.single.text, '散歩した');
      expect(repository.items.single.photoIds, isEmpty);
    });

    testWidgets('本文は、280文字までしか入力できない', (tester) async {
      await tester.pumpWidget(app());
      await tester.tap(find.text('追加ボタン'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(TextField),
        ),
        'あ' * 300,
      );
      await tester.pump();

      final field = tester.widget<TextField>(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(TextField),
        ),
      );
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
      await tester.enterText(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(TextField),
        ),
        '直した文',
      );
      await tester.pump();
      await tester.tap(find.text('保存'));
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

      await tester.enterText(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(TextField),
        ),
        '書きかけ',
      );
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(repository.items, isEmpty);
    });
  });
}
