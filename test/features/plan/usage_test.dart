import 'dart:convert';
import 'package:auto_diary_ai/features/ai/data/repositories/aws_ai_repository_impl.dart';
import 'package:auto_diary_ai/features/ai/domain/entities/ai_message_request.dart';
import 'package:auto_diary_ai/features/plan/application/providers/plan_provider.dart';
import 'package:auto_diary_ai/features/plan/data/aws_usage_repository_impl.dart';
import 'package:auto_diary_ai/features/plan/domain/entities/plan_type.dart';
import 'package:auto_diary_ai/features/plan/domain/entities/usage_info.dart';
import 'package:auto_diary_ai/features/plan/domain/exceptions/usage_limit_exception.dart';
import 'package:auto_diary_ai/features/plan/domain/repositories/plan_repository.dart';
import 'package:auto_diary_ai/features/plan/domain/repositories/usage_repository.dart';
import 'package:auto_diary_ai/core/app_info/client_id.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class InMemoryPlanRepository implements PlanRepository {
  @override
  Future<PlanType> load() async => PlanType.free;

  @override
  Future<void> save(PlanType plan) async {}
}

class FakeUsageRepository implements UsageRepository {
  UsageInfo? usage;

  @override
  Future<UsageInfo?> fetch() async => usage;
}

http.Response jsonResponse(int status, Object body) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    status,
    headers: {'content-type': 'application/json'},
  );
}

void main() {
  group('UsageInfo', () {
    test('サーバーの応答から、プランと使用量を読み取る', () {
      final usage = UsageInfo.fromJson({
        'plan': 'paid',
        'usage': {
          'usedTokens': 1200,
          'limitTokens': 4800,
          'resetsAt': '2026-11-01T00:00:00+09:00',
        },
      })!;

      expect(usage.plan, PlanType.paid);
      expect(usage.usedTokens, 1200);
      expect(usage.remainingTokens, 3600);
      expect(usage.ratio, 0.25);
      expect(usage.isExceeded, isFalse);
      expect(usage.resetsAt, isNotNull);
    });

    test('上限に達したら、使えない状態になる', () {
      const usage = UsageInfo(usedTokens: 5000, limitTokens: 5000);

      expect(usage.isExceeded, isTrue);
      expect(usage.remainingTokens, 0);
      expect(usage.ratio, 1);

      // 上限を超えて集計されても、割合や残りはおかしくならない
      const over = UsageInfo(usedTokens: 6000, limitTokens: 5000);
      expect(over.ratio, 1);
      expect(over.remainingTokens, 0);
    });

    test('使用量が含まれない応答や、形式が違う応答はnull', () {
      expect(UsageInfo.fromJson({'answer': 'こんにちは'}), isNull);
      expect(UsageInfo.fromJson('text'), isNull);
      expect(
        UsageInfo.fromJson({
          'usage': {'usedTokens': 'many', 'limitTokens': 10},
        }),
        isNull,
      );
    });

    test('未知のプランは、プラン不明として扱う', () {
      final usage = UsageInfo.fromJson({
        'plan': 'platinum',
        'usage': {'usedTokens': 1, 'limitTokens': 10},
      })!;

      expect(usage.plan, isNull);
    });
  });

  group('AwsAiRepositoryImpl', () {
    const request = AiMessageRequest(message: 'こんにちは');

    test('回答と使用量を受け取り、端末のIDを送る', () async {
      String? clientId;

      final repository = AwsAiRepositoryImpl(
        'https://example.com',
        clientId: () async => 'abc123',
        client: MockClient((http.Request r) async {
          clientId = r.headers['X-Client-Id'];

          return jsonResponse(200, {
            'answer': 'タイトル: 日記\n本文:\nきょうは晴れ',
            'plan': 'free',
            'usage': {'usedTokens': 100, 'limitTokens': 1000},
          });
        }),
      );

      final reply = await repository.sendMessage(request);

      expect(clientId, 'abc123');
      expect(reply.answer, contains('きょうは晴れ'));
      expect(reply.usage!.usedTokens, 100);
      expect(reply.usage!.plan, PlanType.free);
    });

    test('サーバーが使用量を返さなくても、回答は受け取れる', () async {
      final repository = AwsAiRepositoryImpl(
        'https://example.com',
        client: MockClient((_) async => jsonResponse(200, {'answer': 'ok'})),
      );

      final reply = await repository.sendMessage(request);

      expect(reply.answer, 'ok');
      expect(reply.usage, isNull);
    });

    test('上限に達している場合は、使用量つきの例外になる', () async {
      final repository = AwsAiRepositoryImpl(
        'https://example.com',
        client: MockClient((_) async {
          return jsonResponse(429, {
            'error': 'usage_limit_exceeded',
            'plan': 'free',
            'usage': {
              'usedTokens': 1000,
              'limitTokens': 1000,
              'resetsAt': '2026-11-01T00:00:00+09:00',
            },
          });
        }),
      );

      await expectLater(
        repository.sendMessage(request),
        throwsA(
          isA<UsageLimitExceededException>()
              .having((e) => e.usage?.isExceeded, '上限に達している', true),
        ),
      );
    });

    test('上限に達した応答に使用量がなくても、上限の例外になる', () async {
      final repository = AwsAiRepositoryImpl(
        'https://example.com',
        client: MockClient((_) async => http.Response('limit', 429)),
      );

      await expectLater(
        repository.sendMessage(request),
        throwsA(isA<UsageLimitExceededException>()),
      );
    });
  });

  group('AwsUsageRepositoryImpl', () {
    AwsUsageRepositoryImpl build(http.Client client) {
      return AwsUsageRepositoryImpl(
        'https://example.com',
        clientId: () async => 'abc123',
        client: client,
      );
    }

    test('使用量を取得する', () async {
      final repository = build(
        MockClient((_) async {
          return jsonResponse(200, {
            'plan': 'free',
            'usage': {'usedTokens': 10, 'limitTokens': 100},
          });
        }),
      );

      expect((await repository.fetch())!.limitTokens, 100);
    });

    test('サーバーが未対応・通信できない場合は、nullを返す', () async {
      expect(
        await build(MockClient((_) async => http.Response('', 404))).fetch(),
        isNull,
      );
      expect(
        await build(MockClient((_) async => throw http.ClientException('x')))
            .fetch(),
        isNull,
      );
    });
  });

  group('UsageNotifier', () {
    late FakeUsageRepository usageRepository;
    late ProviderContainer container;

    setUp(() {
      usageRepository = FakeUsageRepository();
      container = ProviderContainer(
        overrides: [
          planRepositoryProvider.overrideWithValue(InMemoryPlanRepository()),
          usageRepositoryProvider.overrideWithValue(usageRepository),
        ],
      );
      addTearDown(container.dispose);
    });

    test('取得した使用量を反映し、サーバーが返したプランにアプリも合わせる', () async {
      usageRepository.usage = const UsageInfo(
        plan: PlanType.paid,
        usedTokens: 1,
        limitTokens: 10,
      );

      await container.read(usageProvider.notifier).refresh();

      expect(container.read(usageProvider)!.usedTokens, 1);
      expect(container.read(planTypeProvider), PlanType.paid);
    });

    test('取得できなかった場合は、前の使用量のままにする', () async {
      container.read(usageProvider.notifier).update(
            const UsageInfo(usedTokens: 5, limitTokens: 10),
          );
      usageRepository.usage = null;

      await container.read(usageProvider.notifier).refresh();

      expect(container.read(usageProvider)!.usedTokens, 5);
    });
  });

  test('端末のIDは、毎回違う32桁の英数字になる', () {
    final a = ClientId.generate();
    final b = ClientId.generate();

    expect(a, matches(RegExp(r'^[0-9a-f]{32}$')));
    expect(a, isNot(b));
  });
}
