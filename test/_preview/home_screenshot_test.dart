// 一時的な、画面を画像にするテスト(コミットしない)
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:auto_diary_ai/app/theme/theme_util.dart';
import 'package:auto_diary_ai/features/calendar/presentation/ui/calendar_screen.dart';
import 'package:auto_diary_ai/features/diary/application/providers/diary_providers.dart';
import 'package:auto_diary_ai/features/tutorial/application/tutorial_providers.dart';
import 'package:auto_diary_ai/features/tutorial/data/tutorial_seen_store.dart';
import 'package:auto_diary_ai/features/diary/domain/entities/diary.dart';
import 'package:auto_diary_ai/features/memo/application/providers/memo_providers.dart';
import 'package:auto_diary_ai/features/memo/domain/entities/memo.dart';
import 'package:auto_diary_ai/features/memo/presentation/ui/memo_list_view.dart';
import 'package:auto_diary_ai/features/diary_create/application/providers/diary_usecase_providers.dart';
import 'package:auto_diary_ai/features/diary_create/domain/entities/photo.dart';
import 'package:auto_diary_ai/features/diary_create/domain/usecases/get_photo_thumbnail_usecase.dart';
import 'package:auto_diary_ai/features/home/presentation/ui/widgets/diary_timeline_view.dart';
import 'package:auto_diary_ai/features/home/presentation/ui/widgets/home_fab.dart';
import 'package:auto_diary_ai/common/widgets/month_bar.dart';
import 'package:auto_diary_ai/features/home/presentation/ui/widgets/home_scaffold.dart';
import 'package:auto_diary_ai/features/home/domain/services/timeline_entries.dart';
import 'package:auto_diary_ai/features/diary_create/presentation/ui/diary_create_screen.dart';
import 'package:auto_diary_ai/features/diary_create/presentation/ui/diary_ai_screen.dart';
import 'package:auto_diary_ai/features/diary_create/presentation/ui/summary_diary_screen.dart';
import 'package:auto_diary_ai/features/location/application/providers/location_providers.dart';
import 'package:auto_diary_ai/features/location/domain/entities/timeline_item.dart';
import 'package:auto_diary_ai/features/location/domain/usecases/get_timeline_by_date_usecase.dart';
import 'package:auto_diary_ai/features/plan/application/providers/plan_provider.dart';
import 'package:auto_diary_ai/features/plan/domain/entities/plan_type.dart';
import 'package:auto_diary_ai/features/plan/domain/entities/usage_info.dart';
import 'package:auto_diary_ai/features/plan/domain/repositories/plan_repository.dart';
import 'package:auto_diary_ai/features/plan/domain/repositories/usage_repository.dart';
import 'package:auto_diary_ai/features/share/application/providers/share_providers.dart';
import 'package:auto_diary_ai/features/share/domain/entities/shared_post.dart';
import 'package:auto_diary_ai/features/share/domain/usecases/get_shared_posts_usecase.dart';
import 'package:auto_diary_ai/features/memo/domain/repositories/memo_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeThumb implements GetPhotoThumbnailUseCase {
  @override
  Future<Uint8List?> execute(Photo photo) async => base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAgAAAAIAQMAAAD+wSzIAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAAGUExURZ+wzP///2W1YuEAAAABYktHRAH/Ai3eAAAAB3RJTUUH6gsQASsELB2njQAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyNi0xMS0xNlQwMTo0MzowNCswMDowMGroENwAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjYtMTEtMTZUMDE6NDM6MDQrMDA6MDAbtahgAAAAKHRFWHRkYXRlOnRpbWVzdGFtcAAyMDI2LTExLTE2VDAxOjQzOjA0KzAwOjAwTKCJvwAAAAtJREFUCNdjYEAFAAAQAAGhxSHBAAAAAElFTkSuQmCC');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Diary diary(int day, String title, {int hour = 9, bool ai = false, bool photo = false}) =>
    Diary(
      date: DateTime(2026, 10, day, hour),
      title: title,
      content: '',
      isAiGenerated: ai,
      photoIds: photo ? const ['p'] : const [],
      createdAt: DateTime(2026, 10, day, hour),
    );

Future<void> loadFont() async {
  final bytes = File('/Library/Fonts/Arial Unicode.ttf').readAsBytesSync();
  final loader = FontLoader('TestJP')..addFont(Future.value(ByteData.view(bytes.buffer)));
  await loader.load();
}

Widget screen(List<Diary> items, {String month = '2026-10'}) {
  final months = ['2026-10', '2026-03'];
  return ProviderScope(
    overrides: [getPhotoThumbnailUseCaseProvider.overrideWithValue(_FakeThumb())],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeUtil.appTheme(useGoogleFonts: false, fontFamily: 'TestJP'),
      home: HomeScaffold(
        title: 'あなたの軌跡',
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.calendar_month_outlined)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.map_outlined)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.menu)),
        ],
        body: Stack(
          children: [
            Column(
              children: [
                MonthBar(
                  months: months,
                  selectedMonth: month,
                  recordedDays: countRecordedDays(items),
                  onChanged: (_) {},
                ),
                Expanded(
                  child: DiaryTimelineView(
                    months: [month],
                    itemsPerMonth: {month: items},
                    pageController: PageController(),
                    onPageChanged: (_) {},
                  ),
                ),
              ],
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: HomeFab(heroTag: 'x', tooltip: 't', label: '日記を書く', onPressed: () {}),
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: 0,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: '日記'),
            NavigationDestination(icon: Icon(Icons.edit_note_outlined), selectedIcon: Icon(Icons.edit_note), label: 'ひとこと'),
          ],
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(loadFont);

  testWidgets('home many', (tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(screen([
      diary(27, '計画づくり', ai: true),
      diary(26, '打ち合わせの調整', photo: true),
      diary(26, '夜の散歩', hour: 21),
      diary(25, 'ふらっと出かけた休日、駅前のカフェでゆっくり本を読んでから、夕方まで街を歩いた一日'),
      diary(24, '映画と読書の休日'),
      diary(23, '打ち合わせの調整', photo: true, ai: true),
    ]));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('home_many.png'));
  });

  testWidgets('home sparse', (tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(screen([diary(27, '計画づくり'), diary(26, '打ち合わせの調整', photo: true)]));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('home_sparse.png'));
  });

  testWidgets('month sheet', (tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(screen([diary(27, '計画づくり'), diary(26, '打ち合わせの調整'), diary(25, 'ふらっと'), diary(24, '映画')]));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await tester.tap(find.byKey(const Key('homeMonthLabel')));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('month_sheet.png'));
  });

  testWidgets('calendar', (tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    final now = DateTime.now();
    Diary d(int day, String t, {int hour = 9, bool ai = false, bool photo = false}) => Diary(
          date: DateTime(now.year, now.month, day, hour),
          title: t,
          content: '',
          isAiGenerated: ai,
          photoIds: photo ? const ['p'] : const [],
          createdAt: DateTime(now.year, now.month, day, hour),
        );
    final items = [
      d(1, '次の企画の準備'), d(2, '打ち合わせの調整'), d(3, '運動と料理の一日'), d(4, '映画と読書の休日'),
      d(5, '料理教室の発表会'), d(6, '計画づくり'), d(7, '次の企画の準備'), d(8, '打ち合わせの調整'),
      d(9, '計画づくり', photo: true), d(10, '本と散歩の一日'), d(11, '10キロのレースを走り切った'),
      d(12, '計画づくり'), d(13, '次の企画の準備'), d(14, '遠足に行った', photo: true), d(14, '夜の記録', hour: 21),
      d(15, '母が上京してきた'),
    ];
    await tester.pumpWidget(ProviderScope(
      overrides: [
        getPhotoThumbnailUseCaseProvider.overrideWithValue(_FakeThumb()),
        tutorialSeenStoreProvider.overrideWithValue(_Seen()),
        diariesProvider.overrideWith((ref) => Stream.value(items)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeUtil.appTheme(useGoogleFonts: false, fontFamily: 'TestJP'),
        home: const CalendarScreen(),
      ),
    ));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('calendar.png'));
  });

  testWidgets('memo', (tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    final memos = [
      Memo(text: '駅前のカフェで、ゆっくり本を読んだ。', createdAt: DateTime(2026, 11, 16, 14, 20)),
      Memo(text: '夜は軽く走った。風が気持ちよかった。', createdAt: DateTime(2026, 11, 15, 21, 5)),
      Memo(text: '朝のコーヒー', createdAt: DateTime(2026, 11, 15, 8, 30)),
      Memo(text: '打ち合わせが長引いた。帰りに、少しだけ遠回りをして帰った。', createdAt: DateTime(2026, 10, 30, 19, 0)),
      Memo(text: '映画を観た。', createdAt: DateTime(2026, 10, 24, 15, 40)),
    ];
    await tester.pumpWidget(ProviderScope(
      overrides: [
        getPhotoThumbnailUseCaseProvider.overrideWithValue(_FakeThumb()),
        allMemosProvider.overrideWith((ref) async => memos),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeUtil.appTheme(useGoogleFonts: false, fontFamily: 'TestJP'),
        home: Scaffold(
          appBar: AppBar(title: const Text('あなたの軌跡')),
          body: const MemoListView(),
        ),
      ),
    ));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('memo.png'));
  });

  Future<void> shot(WidgetTester tester, Widget home, String name, {double height = 5200}) async {
    tester.view.physicalSize = Size(1080, height);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        getPhotoThumbnailUseCaseProvider.overrideWithValue(_FakeThumb()),
        tutorialSeenStoreProvider.overrideWithValue(_Seen()),
        usageRepositoryProvider.overrideWithValue(_Usage()),
        planRepositoryProvider.overrideWithValue(_Plan()),
        getTimelineByDateUseCaseProvider.overrideWithValue(_Timeline()),
        getSharedPostsUseCaseProvider.overrideWithValue(_Posts()),
        memoRepositoryProvider.overrideWithValue(_Memos()),
        diariesProvider.overrideWith((ref) => Stream.value([
              Diary(id: 1, date: DateTime(2026, 1, 1), title: 'a', content: 'a', isAiGenerated: false, createdAt: DateTime(2026, 1, 1)),
            ])),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeUtil.appTheme(useGoogleFonts: false, fontFamily: 'TestJP'),
        home: home,
      ),
    ));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile(name));
  }

  testWidgets('write', (tester) => shot(tester, const DiaryCreateScreen(), 'write.png', height: 2200));
  testWidgets('writeai', (tester) => shot(tester, const DiaryAiScreen(), 'writeai.png'));
  testWidgets('review', (tester) => shot(tester, const SummaryDiaryScreen(), 'review.png'));
}

class _Usage implements UsageRepository {
  @override
  Future<UsageInfo?> fetch({PlanType plan = PlanType.free}) async =>
      UsageInfo(usedTokens: 0, limitTokens: 16600000, resetsAt: DateTime(2026, 12, 1));
}

class _Plan implements PlanRepository {
  @override
  Future<PlanType> load() async => PlanType.free;
  @override
  Future<void> save(PlanType plan) async {}
}

class _Timeline implements GetTimelineByDateUseCase {
  @override
  Future<List<TimelineItem>> execute(DateTime date, {bool estimatePlaces = true}) async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Posts implements GetSharedPostsUseCase {
  @override
  Future<List<SharedPost>> execute(DateTime date) async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Memos implements MemoRepository {
  @override
  Future<List<Memo>> findBetween(DateTime start, DateTime end) async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Seen implements TutorialSeenStore {
  @override
  Future<bool> hasSeen(String id) async => true;
  @override
  Future<void> markSeen(String id) async {}
  @override
  Future<void> clearAll() async {}
}