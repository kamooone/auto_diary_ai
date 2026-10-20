import 'dart:convert';
import 'package:auto_diary_ai/features/ai/data/repositories/aws_ai_repository_impl.dart';
import 'package:auto_diary_ai/features/ai/domain/entities/ai_message_request.dart';
import 'package:auto_diary_ai/features/plan/application/providers/plan_provider.dart';
import 'package:auto_diary_ai/features/plan/data/aws_usage_repository_impl.dart';
import 'package:auto_diary_ai/features/plan/domain/entities/plan_type.dart';
import 'package:auto_diary_ai/features/plan/domain/entities/usage_info.dart';
import 'package:auto_diary_ai/features/plan/domain/repositories/plan_repository.dart';
import 'package:auto_diary_ai/features/plan/domain/repositories/usage_repository.dart';
import 'package:auto_diary_ai/features/points/application/providers/device_link_provider.dart';
import 'package:auto_diary_ai/features/points/application/providers/pairing_provider.dart';
import 'package:auto_diary_ai/features/points/data/aws_pairing_repository_impl.dart';
import 'package:auto_diary_ai/features/points/domain/entities/pairing_session.dart';
import 'package:auto_diary_ai/features/points/domain/repositories/device_token_store.dart';
import 'package:auto_diary_ai/features/points/domain/repositories/pairing_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class InMemoryTokenStore implements DeviceTokenStore {
  String? token;

  @override
  Future<String?> load() async => token;

  @override
  Future<void> save(String token) async => this.token = token;

  @override
  Future<void> clear() async => token = null;
}

class InMemoryPlanRepository implements PlanRepository {
  @override
  Future<PlanType> load() async => PlanType.free;

  @override
  Future<void> save(PlanType plan) async {}
}

class NoUsageRepository implements UsageRepository {
  var fetchCount = 0;

  @override
  Future<UsageInfo?> fetch({PlanType plan = PlanType.free}) async {
    fetchCount++;
    return null;
  }
}

class FakePairingRepository implements PairingRepository {
  final results = <Object>[];
  Object? startError;
  var claimCount = 0;
  String? startedLabel;

  PairingSession session = PairingSession(
    code: '123456',
    claimSecret: 'secret',
    expiresAt: DateTime.now().add(const Duration(minutes: 10)),
  );

  @override
  Future<PairingSession> start({required String label}) async {
    startedLabel = label;
    final error = startError;
    if (error != null) throw error;
    return session;
  }

  final unlinkedTokens = <String>[];

  @override
  Future<void> unlink(String deviceToken) async {
    unlinkedTokens.add(deviceToken);
  }

  @override
  Future<PairingClaimResult> claim(PairingSession session) async {
    claimCount++;
    final next = results.isEmpty ? const PairingPending() : results.removeAt(0);
    if (next is PairingClaimResult) return next;
    throw next;
  }
}

http.Response jsonResponse(int status, Object body) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    status,
    headers: {'content-type': 'application/json'},
  );
}

void main() {
  group('pointsWebUri', () {
    test('コードを渡すと、pairの値として付ける', () {
      expect(
        pointsWebUri('https://example.com/index.html', code: '123456')
            .toString(),
        'https://example.com/index.html?pair=123456',
      );
    });

    test('コードがなければ、そのままのURL', () {
      expect(
        pointsWebUri('https://example.com/index.html').toString(),
        'https://example.com/index.html',
      );
    });
  });

  group('AwsPairingRepositoryImpl', () {
    AwsPairingRepositoryImpl build(http.Client client) =>
        AwsPairingRepositoryImpl('https://example.com', client: client);

    test('解除をサーバーに伝える。通信できなくても例外にしない', () async {
      String? token;
      final repository = build(MockClient((r) async {
        expect(r.url.path, '/device/unlink');
        token = r.headers['X-Device-Token'];
        return jsonResponse(200, {'unlinked': true});
      }));

      await repository.unlink('id.secret');
      expect(token, 'id.secret');

      final offline = build(MockClient((r) async {
        throw http.ClientException('offline');
      }));
      await offline.unlink('id.secret');
    });

    test('コードを発行する', () async {
      Map<String, dynamic>? sent;
      final repository = build(MockClient((r) async {
        expect(r.url.path, '/pairing/start');
        sent = jsonDecode(r.body);
        return jsonResponse(200, {
          'code': '749947',
          'claimSecret': 'abc',
          'expiresAt': 1792422783,
        });
      }));

      final session = await repository.start(label: 'Android');

      expect(sent, {'label': 'Android'});
      expect(session.code, '749947');
      expect(session.claimSecret, 'abc');
      expect(session.expiresAt.millisecondsSinceEpoch, 1792422783 * 1000);
    });

    test('発行に失敗したら、例外になる', () async {
      final repository = build(MockClient((_) async => http.Response('', 500)));

      await expectLater(
        repository.start(label: 'Android'),
        throwsA(isA<PairingException>()),
      );
    });

    test('確認の結果を、状態に分ける', () async {
      final session = FakePairingRepository().session;

      PairingRepository with_(http.Response response) =>
          build(MockClient((_) async => response));

      expect(
        await with_(jsonResponse(202, {'status': 'pending'})).claim(session),
        isA<PairingPending>(),
      );
      expect(
        await with_(jsonResponse(404, {'status': 'expired'})).claim(session),
        isA<PairingExpired>(),
      );

      final linked = await with_(
        jsonResponse(200, {'status': 'linked', 'deviceToken': 'id.secret'}),
      ).claim(session);

      expect(linked, isA<PairingLinked>());
      expect((linked as PairingLinked).deviceToken, 'id.secret');
    });

    test('確認で、コードと合言葉を送る', () async {
      Map<String, dynamic>? sent;
      final repository = build(MockClient((r) async {
        expect(r.url.path, '/pairing/claim');
        sent = jsonDecode(r.body);
        return jsonResponse(202, {'status': 'pending'});
      }));

      await repository.claim(FakePairingRepository().session);

      expect(sent, {'code': '123456', 'claimSecret': 'secret'});
    });

    test('通信できない場合は、例外になる', () async {
      final repository = build(
        MockClient((_) async => throw http.ClientException('x')),
      );

      await expectLater(
        repository.claim(FakePairingRepository().session),
        throwsA(isA<PairingException>()),
      );
    });
  });

  group('PairingNotifier', () {
    late FakePairingRepository pairingRepository;
    late InMemoryTokenStore store;
    late NoUsageRepository usageRepository;
    late ProviderContainer container;

    setUp(() {
      pairingRepository = FakePairingRepository();
      store = InMemoryTokenStore();
      usageRepository = NoUsageRepository();
      container = ProviderContainer(
        overrides: [
          pairingRepositoryProvider.overrideWithValue(pairingRepository),
          deviceTokenStoreProvider.overrideWithValue(store),
          planRepositoryProvider.overrideWithValue(InMemoryPlanRepository()),
          usageRepositoryProvider.overrideWithValue(usageRepository),
          pairingPollIntervalProvider
              .overrideWithValue(const Duration(milliseconds: 10)),
          pairingLabelProvider.overrideWithValue('テスト端末'),
        ],
      );
      addTearDown(container.dispose);
    });

    Future<void> waitFor(bool Function() condition) async {
      for (var i = 0; i < 100 && !condition(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    }

    test('コードを発行すると、確定を待つ状態になる', () async {
      final subscription = container.listen(pairingProvider, (_, __) {});
      addTearDown(subscription.close);

      await container.read(pairingProvider.notifier).start();

      final state = container.read(pairingProvider);
      expect(state.phase, PairingPhase.waiting);
      expect(state.session!.code, '123456');
      expect(pairingRepository.startedLabel, 'テスト端末');
    });

    test('Webで確定されたら、トークンを保存して紐づけ済みにする', () async {
      final subscription = container.listen(pairingProvider, (_, __) {});
      addTearDown(subscription.close);
      pairingRepository.results.addAll([
        const PairingPending(),
        const PairingLinked('id.secret'),
      ]);

      await container.read(pairingProvider.notifier).start();
      await waitFor(() => store.token != null);
      await waitFor(() => usageRepository.fetchCount > 0);

      expect(store.token, 'id.secret');
      expect(container.read(deviceLinkProvider), isTrue);
      expect(container.read(pairingProvider).phase, PairingPhase.idle);
      // 紐づけたあとは、トークン残高を反映するため、使用量を取得し直す
      expect(usageRepository.fetchCount, 1);
    });

    test('期限切れの応答なら、期限切れの状態になる', () async {
      final subscription = container.listen(pairingProvider, (_, __) {});
      addTearDown(subscription.close);
      pairingRepository.results.add(const PairingExpired());

      await container.read(pairingProvider.notifier).start();
      await waitFor(
        () => container.read(pairingProvider).phase == PairingPhase.expired,
      );

      expect(container.read(pairingProvider).phase, PairingPhase.expired);
      expect(store.token, isNull);
    });

    test('有効期限を過ぎたら、サーバーに聞かずに期限切れにする', () async {
      final subscription = container.listen(pairingProvider, (_, __) {});
      addTearDown(subscription.close);
      pairingRepository.session = PairingSession(
        code: '111111',
        claimSecret: 's',
        expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
      );

      await container.read(pairingProvider.notifier).start();
      await waitFor(
        () => container.read(pairingProvider).phase == PairingPhase.expired,
      );

      expect(container.read(pairingProvider).phase, PairingPhase.expired);
      expect(pairingRepository.claimCount, 0);
    });

    test('通信できなくても、期限まで確認を続ける', () async {
      final subscription = container.listen(pairingProvider, (_, __) {});
      addTearDown(subscription.close);
      pairingRepository.results.addAll([
        PairingException('network'),
        const PairingLinked('id.secret'),
      ]);

      await container.read(pairingProvider.notifier).start();
      await waitFor(() => store.token != null);

      expect(store.token, 'id.secret');
    });

    test('発行できなかった場合は、失敗の状態になる', () async {
      final subscription = container.listen(pairingProvider, (_, __) {});
      addTearDown(subscription.close);
      pairingRepository.startError = PairingException('x');

      await container.read(pairingProvider.notifier).start();

      expect(container.read(pairingProvider).phase, PairingPhase.failed);
    });

    test('キャンセルすると、確認をやめる', () async {
      final subscription = container.listen(pairingProvider, (_, __) {});
      addTearDown(subscription.close);

      final notifier = container.read(pairingProvider.notifier);
      await notifier.start();
      notifier.cancel();
      final count = pairingRepository.claimCount;
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(container.read(pairingProvider).phase, PairingPhase.idle);
      expect(pairingRepository.claimCount, count);
    });
  });

  group('端末用トークンの送信', () {
    final request = AiMessageRequest(message: 'こんにちは', images: const []);

    test('紐づけ済みなら、AIの呼び出しにトークンを付ける', () async {
      String? sent;
      final repository = AwsAiRepositoryImpl(
        'https://example.com',
        clientId: () async => 'abc123',
        deviceToken: () async => 'id.secret',
        client: MockClient((r) async {
          sent = r.headers['X-Device-Token'];
          return jsonResponse(200, {'answer': 'ok'});
        }),
      );

      await repository.sendMessage(request);

      expect(sent, 'id.secret');
    });

    test('紐づけていなければ、トークンは付けない', () async {
      var hasHeader = true;
      final repository = AwsAiRepositoryImpl(
        'https://example.com',
        clientId: () async => 'abc123',
        deviceToken: () async => null,
        client: MockClient((r) async {
          hasHeader = r.headers.containsKey('X-Device-Token');
          return jsonResponse(200, {'answer': 'ok'});
        }),
      );

      await repository.sendMessage(request);

      expect(hasHeader, isFalse);
    });

    test('サーバーに断られたら、トークンを捨てて、紐づけなしで送り直す', () async {
      final tokens = <String?>[];
      var invalidated = 0;
      final repository = AwsAiRepositoryImpl(
        'https://example.com',
        clientId: () async => 'abc123',
        deviceToken: () async => 'id.secret',
        onInvalidDeviceToken: () async => invalidated++,
        client: MockClient((r) async {
          tokens.add(r.headers['X-Device-Token']);
          if (r.headers.containsKey('X-Device-Token')) {
            return jsonResponse(401, {'error': 'invalid_device_token'});
          }
          return jsonResponse(200, {'answer': 'ok'});
        }),
      );

      final reply = await repository.sendMessage(request);

      expect(reply.answer, 'ok');
      expect(tokens, ['id.secret', null]);
      expect(invalidated, 1);
    });

    test('使用量の取得に、プランとトークンを付ける', () async {
      Uri? url;
      String? token;
      final repository = AwsUsageRepositoryImpl(
        'https://example.com',
        clientId: () async => 'abc123',
        deviceToken: () async => 'id.secret',
        client: MockClient((r) async {
          url = r.url;
          token = r.headers['X-Device-Token'];
          return jsonResponse(200, {
            'plan': 'paid',
            'usage': {'usedTokens': 1, 'limitTokens': 100},
            'tokenBalance': 40,
          });
        }),
      );

      final usage = await repository.fetch(plan: PlanType.paid);

      expect(url!.path, '/plan/usage');
      expect(url!.queryParameters, {'plan': 'paid'});
      expect(token, 'id.secret');
      expect(usage!.tokenBalance, 40);
    });

    test('使用量の取得で断られたら、トークンを捨てて取得し直す', () async {
      var invalidated = 0;
      final repository = AwsUsageRepositoryImpl(
        'https://example.com',
        clientId: () async => 'abc123',
        deviceToken: () async => 'id.secret',
        onInvalidDeviceToken: () async => invalidated++,
        client: MockClient((r) async {
          if (r.headers.containsKey('X-Device-Token')) {
            return jsonResponse(401, {'error': 'invalid_device_token'});
          }
          return jsonResponse(200, {
            'usage': {'usedTokens': 1, 'limitTokens': 100},
          });
        }),
      );

      final usage = await repository.fetch();

      expect(usage!.limitTokens, 100);
      expect(invalidated, 1);
    });
  });

  group('DeviceLinkNotifier', () {
    test('保存済みのトークンがあれば、紐づけ済みになる', () async {
      final store = InMemoryTokenStore()..token = 'id.secret';
      final container = ProviderContainer(
        overrides: [deviceTokenStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);

      container.read(deviceLinkProvider);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(deviceLinkProvider), isTrue);
    });

    test('解除すると、トークンを消して未紐づけになる', () async {
      final store = InMemoryTokenStore()..token = 'id.secret';
      final container = ProviderContainer(
        overrides: [deviceTokenStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);

      await container.read(deviceLinkProvider.notifier).unlink();

      expect(store.token, isNull);
      expect(container.read(deviceLinkProvider), isFalse);
    });

    test('ユーザーが解除すると、サーバーにも伝える', () async {
      final store = InMemoryTokenStore()..token = 'id.secret';
      final repository = FakePairingRepository();
      final container = ProviderContainer(
        overrides: [
          deviceTokenStoreProvider.overrideWithValue(store),
          pairingRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(deviceLinkProvider.notifier).unlinkFromServer();

      expect(repository.unlinkedTokens, ['id.secret']);
      expect(store.token, isNull);
      expect(container.read(deviceLinkProvider), isFalse);
    });
  });
}
