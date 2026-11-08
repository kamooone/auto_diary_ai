import 'package:auto_diary_ai/features/share/application/providers/share_providers.dart';
import 'package:auto_diary_ai/features/share/domain/entities/shared_post.dart';
import 'package:auto_diary_ai/features/share/domain/repositories/share_repository.dart';
import 'package:auto_diary_ai/features/share/domain/usecases/delete_shared_post_usecase.dart';
import 'package:auto_diary_ai/features/share/domain/usecases/update_shared_post_usecase.dart';
import 'package:auto_diary_ai/features/share/presentation/formatters/shared_post_format.dart';
import 'package:auto_diary_ai/features/share/presentation/ui/shared_post_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class InMemoryShareRepository implements ShareRepository {
  final List<SharedPost> posts;

  InMemoryShareRepository(this.posts);

  @override
  Future<String?> fetchText(String url) async => null;

  @override
  Future<void> save(SharedPost post) async => posts.add(post);

  @override
  Future<List<SharedPost>> findByDate(DateTime date) async => [
        for (final post in posts)
          if (post.receivedAt.year == date.year &&
              post.receivedAt.month == date.month &&
              post.receivedAt.day == date.day)
            post,
      ];

  @override
  Future<List<SharedPost>> findAll() async {
    return [...posts]..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
  }

  @override
  Future<void> update(SharedPost post) async {
    final index = posts.indexWhere((e) => e.id == post.id);
    posts[index] = post;
  }

  @override
  Future<void> delete(int id) async {
    posts.removeWhere((e) => e.id == id);
  }
}

SharedPost post(int id, String text, DateTime receivedAt) {
  return SharedPost(
    id: id,
    url: 'https://x.com/user/status/$id',
    text: text,
    receivedAt: receivedAt,
  );
}

void main() {
  group('ユースケース', () {
    late InMemoryShareRepository repository;

    setUp(() {
      repository = InMemoryShareRepository([
        post(1, 'おはよう', DateTime(2026, 1, 1, 8)),
        post(2, 'ただいま', DateTime(2026, 1, 1, 20)),
      ]);
    });

    test('投稿の本文と日時を修正する。URLは変わらない', () async {
      await UpdateSharedPostUseCase(repository).execute(
        repository.posts.first,
        text: 'おはようございます',
        receivedAt: DateTime(2026, 1, 2, 7, 30),
      );

      final updated = repository.posts.first;
      expect(updated.id, 1);
      expect(updated.text, 'おはようございます');
      expect(updated.receivedAt, DateTime(2026, 1, 2, 7, 30));
      expect(updated.url, 'https://x.com/user/status/1');
    });

    test('保存されていない投稿は、修正も削除もできない', () async {
      final unsaved = SharedPost(
        url: 'https://x.com/a',
        text: 'a',
        receivedAt: DateTime(2026),
      );

      expect(
        () => UpdateSharedPostUseCase(repository)
            .execute(unsaved, text: 'b', receivedAt: DateTime(2026)),
        throwsArgumentError,
      );
      expect(
        () => DeleteSharedPostUseCase(repository).execute(unsaved),
        throwsArgumentError,
      );
    });

    test('投稿を削除する', () async {
      await DeleteSharedPostUseCase(repository).execute(repository.posts.first);

      expect(repository.posts.map((e) => e.id), [2]);
    });
  });

  group('SharedPostFormat', () {
    test('日付は曜日つき、時刻は2桁で表示する', () {
      expect(SharedPostFormat.date(DateTime(2026, 1, 1)), '2026年1月1日（木）');
      expect(SharedPostFormat.time(DateTime(2026, 1, 1, 9, 5)), '09:05');
    });

    test('選んだ日付と時刻を合わせて、秒を0にする', () {
      expect(
        SharedPostFormat.combine(
          DateTime(2026, 3, 4, 23, 59, 59),
          const TimeOfDay(hour: 7, minute: 8),
        ),
        DateTime(2026, 3, 4, 7, 8),
      );
    });
  });

  group('一覧画面', () {
    late InMemoryShareRepository repository;

    Future<void> open(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [shareRepositoryProvider.overrideWithValue(repository)],
          child: const MaterialApp(home: SharedPostListScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('投稿がなければ、その旨を表示する', (tester) async {
      repository = InMemoryShareRepository([]);
      await open(tester);

      expect(find.text('保存したXの投稿はありません'), findsOneWidget);
    });

    testWidgets('日付の新しい順に、日付の見出しつきで表示する', (tester) async {
      repository = InMemoryShareRepository([
        post(1, '古い投稿', DateTime(2026, 1, 1, 8)),
        post(2, '新しい投稿', DateTime(2026, 1, 3, 20)),
        post(3, '同じ日の投稿', DateTime(2026, 1, 3, 9)),
      ]);
      await open(tester);

      expect(find.text('2026年1月3日（土）'), findsOneWidget);
      expect(find.text('2026年1月1日（木）'), findsOneWidget);

      // 新しい日が上、同じ日の中も新しい順
      final newest = tester.getTopLeft(find.text('新しい投稿')).dy;
      final sameDay = tester.getTopLeft(find.text('同じ日の投稿')).dy;
      final oldest = tester.getTopLeft(find.text('古い投稿')).dy;
      expect(newest, lessThan(sameDay));
      expect(sameDay, lessThan(oldest));
    });

    testWidgets('確認して削除すると、一覧から消える', (tester) async {
      repository = InMemoryShareRepository([
        post(1, '消す投稿', DateTime(2026, 1, 1, 8)),
        post(2, '残す投稿', DateTime(2026, 1, 1, 9)),
      ]);
      await open(tester);

      // 一覧は新しい順なので、古い方(消す投稿)の削除ボタンは2番目
      await tester.tap(find.byTooltip('削除').last);
      await tester.pumpAndSettle();

      // 確認のダイアログ
      expect(find.text('この投稿を削除しますか？'), findsOneWidget);

      await tester.tap(find.text('削除'));
      await tester.pumpAndSettle();

      expect(repository.posts, hasLength(1));
      expect(find.text('残す投稿'), findsOneWidget);
      expect(find.text('消す投稿'), findsNothing);
    });

    testWidgets('削除の確認でキャンセルすると、消えない', (tester) async {
      repository = InMemoryShareRepository([
        post(1, '投稿', DateTime(2026, 1, 1, 8)),
      ]);
      await open(tester);

      await tester.tap(find.byTooltip('削除'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(repository.posts, hasLength(1));
      expect(find.text('投稿'), findsOneWidget);
    });

    testWidgets('投稿を開いて本文を修正して保存すると、一覧に反映される', (tester) async {
      repository = InMemoryShareRepository([
        post(1, '修正前', DateTime(2026, 1, 1, 8)),
      ]);
      await open(tester);

      await tester.tap(find.text('修正前'));
      await tester.pumpAndSettle();

      // 変更するまでは、保存できない
      final save = find.widgetWithText(ElevatedButton, '保存する');
      expect(tester.widget<ElevatedButton>(save).onPressed, isNull);

      await tester.enterText(find.byType(TextField), '修正後');
      await tester.pump();
      expect(tester.widget<ElevatedButton>(save).onPressed, isNotNull);

      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(repository.posts.single.text, '修正後');
      expect(find.text('修正後'), findsOneWidget);
    });

    testWidgets('編集画面から削除すると、一覧から消える', (tester) async {
      repository = InMemoryShareRepository([
        post(1, '編集中の投稿', DateTime(2026, 1, 1, 8)),
      ]);
      await open(tester);

      await tester.tap(find.text('編集中の投稿'));
      await tester.pumpAndSettle();

      // 編集画面のアプリバーの削除ボタン
      await tester.tap(find.byTooltip('削除'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('削除').last);
      await tester.pumpAndSettle();

      expect(repository.posts, isEmpty);
      expect(find.text('保存したXの投稿はありません'), findsOneWidget);
    });
  });
}
