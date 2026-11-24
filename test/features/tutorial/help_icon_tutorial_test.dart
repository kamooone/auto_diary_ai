import 'package:auto_diary_ai/features/plan/application/providers/plan_provider.dart';
import 'package:auto_diary_ai/features/plan/domain/entities/plan_type.dart';
import 'package:auto_diary_ai/features/plan/domain/entities/usage_info.dart';
import 'package:auto_diary_ai/features/plan/domain/repositories/plan_repository.dart';
import 'package:auto_diary_ai/features/plan/domain/repositories/usage_repository.dart';
import 'package:auto_diary_ai/features/points/application/providers/device_link_provider.dart';
import 'package:auto_diary_ai/features/points/application/providers/pairing_provider.dart';
import 'package:auto_diary_ai/features/points/domain/entities/pairing_session.dart';
import 'package:auto_diary_ai/features/points/domain/repositories/device_token_store.dart';
import 'package:auto_diary_ai/features/points/domain/repositories/pairing_repository.dart';
import 'package:auto_diary_ai/features/points/presentation/ui/points_page.dart';
import 'package:auto_diary_ai/features/share/application/providers/share_providers.dart';
import 'package:auto_diary_ai/features/share/domain/entities/shared_post.dart';
import 'package:auto_diary_ai/features/share/presentation/ui/shared_post_list_screen.dart';
import 'package:auto_diary_ai/features/tutorial/application/tutorial_providers.dart';
import 'package:auto_diary_ai/features/x_archive/presentation/ui/x_archive_import_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/tutorial_stores.dart';

class _DeviceStore implements DeviceTokenStore {
  @override
  Future<String?> load() async => null;

  @override
  Future<void> save(String token) async {}

  @override
  Future<void> clear() async {}
}

class _Plan implements PlanRepository {
  @override
  Future<PlanType> load() async => PlanType.free;

  @override
  Future<void> save(PlanType plan) async {}
}

class _Usage implements UsageRepository {
  @override
  Future<UsageInfo?> fetch({PlanType plan = PlanType.free}) async => null;
}

class _Pairing implements PairingRepository {
  @override
  Future<PairingSession> start({required String label}) async => PairingSession(
    code: '899026',
    claimSecret: 'secret',
    expiresAt: DateTime.now().add(const Duration(minutes: 10)),
  );

  @override
  Future<void> unlink(String deviceToken) async {}

  @override
  Future<PairingClaimResult> claim(PairingSession session) async =>
      const PairingPending();
}

/// 「?」アイコンがある画面の、初回のチュートリアル
void main() {
  // 画面ごとの、開き方と、チュートリアルの内容
  final screens =
      <
        ({
          String name,
          String id,
          Widget Function() home,
          List<Override> overrides,
          String introTitle,
          String introText,
          String helpText,
        })
      >[
        (
          name: 'ポイント・ゲーム',
          id: 'points',
          home: () => const PointsPage(),
          overrides: [
            deviceTokenStoreProvider.overrideWithValue(_DeviceStore()),
            planRepositoryProvider.overrideWithValue(_Plan()),
            usageRepositoryProvider.overrideWithValue(_Usage()),
            pairingRepositoryProvider.overrideWithValue(_Pairing()),
            pairingPollIntervalProvider.overrideWithValue(
              const Duration(minutes: 5),
            ),
            pairingLabelProvider.overrideWithValue('テスト端末'),
          ],
          introTitle: 'ポイント・ゲーム',
          introText: 'AIが日記を書くときに使う「トークン」に交換できます',
          helpText: 'ポイントとトークンの、くわしい使い方は',
        ),
        (
          name: 'Xのアーカイブを取り込む',
          id: 'x_archive_import',
          home: () => const XArchiveImportPage(),
          overrides: <Override>[],
          introTitle: 'Xのアーカイブを取り込む',
          introText: '過去のポスト(ツイート)のファイルを、このアプリに取り込みます',
          helpText: 'アーカイブの取り込み方は',
        ),
        (
          name: 'Xの投稿一覧',
          id: 'shared_posts',
          home: () => const SharedPostListScreen(),
          overrides: [
            allSharedPostsProvider.overrideWith((ref) async => <SharedPost>[]),
          ],
          introTitle: 'Xの投稿一覧',
          introText: 'Xから共有して保存した投稿を、ここで確認できます',
          helpText: 'Xから共有するしかたは',
        ),
      ];

  for (final screen in screens) {
    group('${screen.name}の、初回のチュートリアル', () {
      late MemoryTutorialStore store;

      Future<void> open(WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              tutorialSeenStoreProvider.overrideWithValue(store),
              ...screen.overrides,
            ],
            child: MaterialApp(home: screen.home()),
          ),
        );
        await tester.pumpAndSettle();
      }

      setUp(() => store = MemoryTutorialStore());

      testWidgets('初めて開くと、画面の説明のあとに、「?」の場所を知らせる(2ページ)', (tester) async {
        await open(tester);

        // 1ページ目: その画面の簡単な説明
        expect(find.text('1 / 2'), findsOneWidget);
        expect(find.text(screen.introTitle), findsWidgets);
        // 画面本体にも、同じ文がある場合があるため、「1つ以上」とする
        expect(find.textContaining(screen.introText), findsWidgets);

        await tester.tap(find.text('次へ'));
        await tester.pumpAndSettle();

        // 2ページ目: 右上の「?」で、くわしく確認できること
        expect(find.text('2 / 2'), findsOneWidget);
        expect(find.text('使い方は「?」で確認できます'), findsOneWidget);
        expect(find.textContaining(screen.helpText), findsOneWidget);
        expect(find.textContaining('右上の「?」'), findsOneWidget);
      });

      testWidgets('最後まで見ると、見たことを覚えて、開き直しても出ない', (tester) async {
        await open(tester);

        await tester.tap(find.text('次へ'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('完了'));
        await tester.pumpAndSettle();

        expect(store.seen, {screen.id});

        await open(tester);
        expect(find.text('1 / 2'), findsNothing);
      });

      testWidgets('見たあとは、最初から出ない', (tester) async {
        store.seen.add(screen.id);

        await open(tester);

        expect(find.text('1 / 2'), findsNothing);
      });
    });
  }
}
