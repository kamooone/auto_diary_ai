import 'package:auto_diary_ai/features/ads/application/ads_provider.dart';
import 'package:auto_diary_ai/features/ai/application/providers/ai_provider.dart';
import 'package:auto_diary_ai/features/ai/domain/entities/ai_message_request.dart';
import 'package:auto_diary_ai/features/ai/domain/entities/ai_reply.dart';
import 'package:auto_diary_ai/features/ai/domain/repositories/ai_repository.dart';
import 'package:auto_diary_ai/features/diary/application/providers/diary_providers.dart';
import 'package:auto_diary_ai/features/diary/domain/entities/diary.dart';
import 'package:auto_diary_ai/features/diary_create/application/providers/diary_usecase_providers.dart';
import 'package:auto_diary_ai/features/diary_create/domain/entities/summary_style.dart';
import 'package:auto_diary_ai/features/diary_create/domain/repositories/summary_style_repository.dart';
import 'package:auto_diary_ai/features/diary_create/presentation/ui/summary_consult_screen.dart';
import 'package:auto_diary_ai/features/diary_create/presentation/ui/summary_diary_screen.dart';
import 'package:auto_diary_ai/features/plan/application/providers/plan_provider.dart';
import 'package:auto_diary_ai/features/plan/domain/entities/plan_type.dart';
import 'package:auto_diary_ai/features/plan/domain/entities/usage_info.dart';
import 'package:auto_diary_ai/features/plan/domain/repositories/usage_repository.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Diary diary(int id, int day) => Diary(
  id: id,
  date: DateTime(2026, 1, day),
  title: 'タイトル$id',
  content: '本文$id',
  isAiGenerated: false,
  createdAt: DateTime(2026, 1, day),
);

class FakeUsage implements UsageRepository {
  @override
  Future<UsageInfo?> fetch({PlanType plan = PlanType.free}) async =>
      const UsageInfo(usedTokens: 0, limitTokens: 100000);
}

class FakeStyleRepository implements SummaryStyleRepository {
  @override
  Future<SummaryStyle> load() async => SummaryStyle.reading;

  @override
  Future<void> save(SummaryStyle style) async {}
}

class FakeAi implements AiRepository {
  /// 指定すると、その完了まで返答を待たせる
  final Completer<void>? hold;

  FakeAi({this.hold});

  @override
  Future<AiReply> sendMessage(AiMessageRequest request) async {
    await hold?.future;

    return const AiReply(
      answer:
          '【相談の回答】\n仕事が中心なので、章立てがおすすめです。\n【書き方の指示】\n仕事と私生活の2章で書く。\n【材料メモ】\nメモ',
    );
  }
}

List<Override> overrides(List<Diary> diaries, {FakeAi? ai}) => [
  diariesProvider.overrideWith((ref) => Stream.value(diaries)),
  usageRepositoryProvider.overrideWithValue(FakeUsage()),
  summaryStyleRepositoryProvider.overrideWithValue(FakeStyleRepository()),
  aiRepositoryProvider.overrideWithValue(ai ?? FakeAi()),
  adsEnabledProvider.overrideWithValue(false),
];

Finder button(String label) =>
    find.ancestor(of: find.text(label), matching: find.bySubtype<ButtonStyleButton>());

bool isEnabled(WidgetTester tester, String label) =>
    tester.widget<ButtonStyleButton>(button(label)).onPressed != null;

void main() {
  group('日記を1つにする画面', () {
    Future<void> open(WidgetTester tester) async {
      // スクロールしなくても全部見える大きさにする
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides([diary(1, 1), diary(2, 2), diary(3, 3)]),
          child: const MaterialApp(home: SummaryDiaryScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('書き方が5つ並び、最初は読み物が選ばれている', (tester) async {
      await open(tester);

      for (final style in SummaryStyle.values) {
        expect(find.text(style.label), findsOneWidget);
      }
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    });

    testWidgets('日記を選ぶまでは、相談も作成もできない', (tester) async {
      await open(tester);

      expect(isEnabled(tester, 'AIに構成を相談する'), isFalse);
      expect(isEnabled(tester, 'AIに1つにしてもらう'), isFalse);
    });

    testWidgets('日記を連結させる(AIを使わない)を選ぶと、AIに伝えたいことの欄が消える', (tester) async {
      await open(tester);

      expect(find.text('AIに追加で伝えたいこと'), findsOneWidget);

      await tester.tap(find.text('日記を連結させる'));
      await tester.pumpAndSettle();

      expect(find.text('AIに追加で伝えたいこと'), findsNothing);
      expect(find.text('日記を1つにする'), findsWidgets);

      await tester.tap(find.text('読み物(ブログ風)'));
      await tester.pumpAndSettle();

      expect(find.text('AIに追加で伝えたいこと'), findsOneWidget);
    });

    testWidgets('自分で指定を選ぶと記入欄が出て、書くまでは作成できない', (tester) async {
      await open(tester);

      await tester.tap(find.text('自分で指定'));
      await tester.pumpAndSettle();

      expect(find.text('どんな書き方にしたいか'), findsOneWidget);
      expect(isEnabled(tester, 'AIに1つにしてもらう'), isFalse);
    });
  });

  group('相談の画面', () {
    testWidgets('AIの回答と提案が出て、「これでいいですか？」で提案を返して閉じる', (tester) async {
      String? result;

      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides([]),
          child: MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await Navigator.of(context).push<String>(
                    MaterialPageRoute(
                      builder: (context) => SummaryConsultScreen(
                        diaries: [diary(1, 1), diary(2, 2)],
                      ),
                    ),
                  );
                },
                child: const Text('開く'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();

      expect(find.text('仕事が中心なので、章立てがおすすめです。'), findsOneWidget);
      expect(find.text('仕事と私生活の2章で書く。'), findsOneWidget);

      await tester.tap(find.textContaining('これでいいですか'));
      await tester.pumpAndSettle();

      expect(result, '仕事と私生活の2章で書く。');
      expect(find.text('開く'), findsOneWidget);
    });

    testWidgets('回答が来るまでは発言できず、来たあとは送れる', (tester) async {
      final hold = Completer<void>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides([], ai: FakeAi(hold: hold)),
          child: MaterialApp(
            home: SummaryConsultScreen(diaries: [diary(1, 1), diary(2, 2)]),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('AIが考えています…'), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);

      hold.complete();
      await tester.pumpAndSettle();

      expect(find.text('AIが考えています…'), findsNothing);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
    });
  });
}
