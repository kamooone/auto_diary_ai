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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Store implements DeviceTokenStore {
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

void main() {
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deviceTokenStoreProvider.overrideWithValue(_Store()),
          planRepositoryProvider.overrideWithValue(_Plan()),
          usageRepositoryProvider.overrideWithValue(_Usage()),
          pairingRepositoryProvider.overrideWithValue(_Pairing()),
          pairingPollIntervalProvider.overrideWithValue(
            const Duration(minutes: 5),
          ),
          pairingLabelProvider.overrideWithValue('テスト端末'),
        ],
        child: const MaterialApp(home: PointsPage()),
      ),
    );
    await tester.pump();
  }

  testWidgets('紐づけていないとき、手順と、コードを発行するボタンが出る', (tester) async {
    await open(tester);

    expect(find.text('アカウントと紐づける'), findsOneWidget);
    expect(find.text('下のボタンで、6桁のコードを発行します'), findsOneWidget);
    expect(find.text('コードを発行する'), findsOneWidget);
    expect(find.text('Webを開く'), findsOneWidget);
  });

  testWidgets('コードを発行すると、1桁ずつの四角で出て、キャンセルで戻れる', (tester) async {
    await open(tester);

    await tester.tap(find.text('コードを発行する'));
    await tester.pump();
    await tester.pump();

    for (final digit in ['8', '9', '0', '2', '6']) {
      expect(find.text(digit), findsWidgets);
    }
    expect(find.byKey(const Key('pairingCode')), findsOneWidget);
    expect(find.text('Webを開いて紐づける'), findsOneWidget);

    await tester.tap(find.text('キャンセル'));
    await tester.pump();
    expect(find.text('コードを発行する'), findsOneWidget);
  });

  testWidgets('狭い画面でも、あふれない', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await open(tester);
    await tester.tap(find.text('コードを発行する'));
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
