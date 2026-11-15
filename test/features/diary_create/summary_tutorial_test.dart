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
import 'package:auto_diary_ai/features/diary_create/presentation/ui/summary_diary_screen.dart';
import 'package:auto_diary_ai/features/plan/application/providers/plan_provider.dart';
import 'package:auto_diary_ai/features/plan/domain/entities/plan_type.dart';
import 'package:auto_diary_ai/features/plan/domain/entities/usage_info.dart';
import 'package:auto_diary_ai/features/plan/domain/repositories/usage_repository.dart';
import 'package:auto_diary_ai/features/tutorial/application/tutorial_providers.dart';
import 'package:auto_diary_ai/features/tutorial/data/tutorial_seen_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeStore implements TutorialSeenStore {
  final seen = <String>{};

  @override
  Future<bool> hasSeen(String id) async => seen.contains(id);

  @override
  Future<void> markSeen(String id) async => seen.add(id);

  @override
  Future<void> clearAll() async => seen.clear();
}

class _FakeUsage implements UsageRepository {
  @override
  Future<UsageInfo?> fetch({PlanType plan = PlanType.free}) async =>
      const UsageInfo(usedTokens: 0, limitTokens: 100000);
}

class _FakeStyle implements SummaryStyleRepository {
  @override
  Future<SummaryStyle> load() async => SummaryStyle.reading;

  @override
  Future<void> save(SummaryStyle style) async {}
}

class _FakeAi implements AiRepository {
  @override
  Future<AiReply> sendMessage(AiMessageRequest request) async =>
      const AiReply(answer: '');
}

Diary _diary(int id) => Diary(
  id: id,
  date: DateTime(2026, 1, id),
  title: 'タイトル$id',
  content: '本文$id',
  isAiGenerated: false,
  createdAt: DateTime(2026, 1, id),
);

void main() {
  testWidgets('振り返り作成画面は、初めて表示したときだけ、チュートリアルを最後まで出す', (tester) async {
    final store = _FakeStore();

    // ふつうのスマホの大きさ(360x780)にする
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    Future<void> open() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tutorialSeenStoreProvider.overrideWithValue(store),
            diariesProvider.overrideWith(
              (ref) => Stream.value([_diary(1), _diary(2), _diary(3)]),
            ),
            usageRepositoryProvider.overrideWithValue(_FakeUsage()),
            summaryStyleRepositoryProvider.overrideWithValue(_FakeStyle()),
            aiRepositoryProvider.overrideWithValue(_FakeAi()),
            adsEnabledProvider.overrideWithValue(false),
          ],
          child: const MaterialApp(home: SummaryDiaryScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    await open();

    expect(find.text('トークン使用量'), findsWidgets);
    expect(find.text('1 / 8'), findsOneWidget);

    // 最後の「完了」まで、「次へ」で進める(下にある部品も、スクロールして見せる)
    for (var i = 0; i < 7; i++) {
      await tester.tap(find.text('次へ'));
      await tester.pumpAndSettle();
    }
    expect(find.text('8 / 8'), findsOneWidget);

    await tester.tap(find.text('完了'));
    await tester.pumpAndSettle();

    expect(store.seen, {'summary_diary'});

    // 見たあとは、開き直しても出ない
    await open();
    expect(find.text('1 / 8'), findsNothing);
  });
}
