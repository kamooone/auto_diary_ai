import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:auto_diary_ai/features/inquiry/application/providers/inquiry_providers.dart';
import 'package:auto_diary_ai/features/inquiry/application/push_registrar.dart';
import 'package:auto_diary_ai/features/inquiry/data/aws_inquiry_repository_impl.dart';
import 'package:auto_diary_ai/features/inquiry/data/aws_push_token_repository_impl.dart';
import 'package:auto_diary_ai/features/inquiry/data/file_inquiry_state_store.dart';
import 'package:auto_diary_ai/features/inquiry/domain/entities/inquiry_category.dart';
import 'package:auto_diary_ai/features/inquiry/domain/entities/inquiry_exception.dart';
import 'package:auto_diary_ai/features/inquiry/domain/entities/inquiry_message.dart';
import 'package:auto_diary_ai/features/inquiry/domain/repositories/inquiry_repository.dart';
import 'package:auto_diary_ai/features/inquiry/domain/repositories/push_token_repository.dart';
import 'package:auto_diary_ai/features/inquiry/domain/services/push_messaging_gateway.dart';
import 'package:auto_diary_ai/features/inquiry/presentation/ui/inquiry_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response json(int status, Object body) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, dynamic> row(String id, String from, String text, String at) => {
  'id': id,
  'from': from,
  'message': text,
  'createdAt': at,
  if (from == 'user') 'category': 'bug',
};

class FakeInquiryRepository implements InquiryRepository {
  final messages = <InquiryMessage>[];
  InquiryException? sendError;
  final sent = <(InquiryCategory, String)>[];

  @override
  Future<InquiryMessage> send({
    required InquiryCategory category,
    required String message,
  }) async {
    if (sendError != null) throw sendError!;
    sent.add((category, message));

    final item = InquiryMessage(
      id: 'u${sent.length}',
      fromDeveloper: false,
      text: message,
      createdAt: DateTime(2026, 11, 9, 12),
      category: category,
    );
    messages.add(item);
    return item;
  }

  @override
  Future<List<InquiryMessage>> fetch() async => [...messages];
}

class FakePushGateway implements PushMessagingGateway {
  String? token = 'token-1';
  var openedFromNotificationAtStart = false;
  final refresh = StreamController<String>.broadcast();
  final foreground = StreamController<void>.broadcast();
  final opened = StreamController<void>.broadcast();

  @override
  Future<String?> getToken() async => token;

  @override
  Stream<String> get onTokenRefresh => refresh.stream;

  @override
  Stream<void> get onForegroundMessage => foreground.stream;

  @override
  Stream<void> get onNotificationOpened => opened.stream;

  @override
  Future<bool> openedFromNotification() async => openedFromNotificationAtStart;
}

class FakePushTokens implements PushTokenRepository {
  final registered = <String>[];
  var fails = false;

  @override
  Future<void> register(String token) async {
    if (fails) throw http.ClientException('x');
    registered.add(token);
  }
}

class MemoryStateStore implements InquiryStateStore {
  var state = const InquiryState();

  @override
  Future<InquiryState> load() async => state;

  @override
  Future<void> markSent() async =>
      state = InquiryState(hasSent: true, seenReplyAt: state.seenReplyAt);

  @override
  Future<void> markSeen(DateTime replyAt) async {
    final seen = state.seenReplyAt;
    if (seen != null && !replyAt.isAfter(seen)) return;
    state = InquiryState(hasSent: state.hasSent, seenReplyAt: replyAt);
  }
}

void main() {
  group('AwsInquiryRepositoryImpl', () {
    AwsInquiryRepositoryImpl build(http.Client client) =>
        AwsInquiryRepositoryImpl(
          'https://example.com',
          clientId: () async => 'abc12345',
          appInfo: () async => '1.0.0 (111)',
          platform: 'android',
          client: client,
        );

    test('端末のID・種類・本文・アプリのバージョンを送る', () async {
      late http.Request request;

      final repository = build(
        MockClient((r) async {
          request = r;
          return json(200, {
            'message': row('1', 'user', '落ちます', '2026-11-09T03:00:00+00:00'),
          });
        }),
      );

      final sent = await repository.send(
        category: InquiryCategory.bug,
        message: '落ちます',
      );

      expect(request.url.toString(), 'https://example.com/inquiries');
      expect(request.method, 'POST');
      expect(request.headers['X-Client-Id'], 'abc12345');
      expect(jsonDecode(request.body), {
        'category': 'bug',
        'message': '落ちます',
        'appVersion': '1.0.0 (111)',
        'platform': 'android',
      });
      expect(sent.text, '落ちます');
      expect(sent.fromDeveloper, isFalse);
      expect(sent.category, InquiryCategory.bug);
    });

    test('やり取りを取得する(開発者の返信も含む)', () async {
      final repository = build(
        MockClient((r) async {
          expect(r.method, 'GET');
          return json(200, {
            'messages': [
              row('1', 'user', '質問', '2026-11-09T03:00:00+00:00'),
              row('2', 'developer', '回答', '2026-11-09T05:00:00+00:00'),
              {'broken': true},
            ],
          });
        }),
      );

      final messages = await repository.fetch();

      expect(messages.map((e) => e.text), ['質問', '回答']);
      expect(messages.map((e) => e.fromDeveloper), [false, true]);
    });

    test('429は「送りすぎ」、それ以外の失敗や通信できない場合は「使えない」', () async {
      Future<InquiryFailure> failure(http.Client client) async {
        try {
          await build(client).fetch();
        } on InquiryException catch (e) {
          return e.reason;
        }
        throw StateError('例外にならなかった');
      }

      expect(
        await failure(MockClient((_) async => json(429, {'error': 'x'}))),
        InquiryFailure.tooMany,
      );
      expect(
        await failure(MockClient((_) async => http.Response('', 500))),
        InquiryFailure.unavailable,
      );
      expect(
        await failure(MockClient((_) async => throw http.ClientException('x'))),
        InquiryFailure.unavailable,
      );
      expect(
        await failure(MockClient((_) async => http.Response('text', 200))),
        InquiryFailure.unavailable,
      );
    });
  });

  group('FileInquiryStateStore', () {
    late Directory dir;
    late FileInquiryStateStore store;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('inquiry_test');
      store = FileInquiryStateStore(
        () async => File('${dir.path}/sub/state.json'),
      );
    });

    tearDown(() => dir.deleteSync(recursive: true));

    test('はじめは、送っておらず、返信も見ていない', () async {
      final state = await store.load();

      expect(state.hasSent, isFalse);
      expect(state.seenReplyAt, isNull);
    });

    test('送ったこと・見た返信の日時を覚え、古い日時には戻らない', () async {
      await store.markSent();
      await store.markSeen(DateTime.utc(2026, 11, 9, 5));
      await store.markSeen(DateTime.utc(2026, 11, 1));

      final state = await store.load();
      expect(state.hasSent, isTrue);
      expect(state.seenReplyAt, DateTime.utc(2026, 11, 9, 5));

      // 送っても、見た日時は消えない
      await store.markSent();
      expect((await store.load()).seenReplyAt, DateTime.utc(2026, 11, 9, 5));
    });

    test('ファイルが壊れていても、はじめの状態として読める', () async {
      File('${dir.path}/sub/state.json')
        ..createSync(recursive: true)
        ..writeAsStringSync('not json');

      expect((await store.load()).hasSent, isFalse);
    });
  });

  group('新しい返信のお知らせ', () {
    late FakeInquiryRepository repository;
    late MemoryStateStore store;
    late ProviderContainer container;

    setUp(() {
      repository = FakeInquiryRepository();
      store = MemoryStateStore();
      container = ProviderContainer(
        overrides: [
          inquiryRepositoryProvider.overrideWithValue(repository),
          inquiryStateStoreProvider.overrideWithValue(store),
        ],
      );
      addTearDown(container.dispose);
    });

    InquiryMessage reply(DateTime at) => InquiryMessage(
      id: 'r',
      fromDeveloper: true,
      text: '返信',
      createdAt: at,
    );

    Future<bool> unread() async {
      container.invalidate(hasUnreadReplyProvider);
      return container.read(hasUnreadReplyProvider.future);
    }

    test('一度も送っていなければ、お知らせしない', () async {
      repository.messages.add(reply(DateTime(2026, 11, 9)));
      expect(await unread(), isFalse);
    });

    test('送ったあとに返信があり、まだ見ていなければ、お知らせする', () async {
      await store.markSent();
      repository.messages.add(reply(DateTime(2026, 11, 9)));

      expect(await unread(), isTrue);
    });

    test('見たあとは、お知らせしない。もっと新しい返信が来れば、また知らせる', () async {
      await store.markSent();
      repository.messages.add(reply(DateTime(2026, 11, 9)));
      await store.markSeen(DateTime(2026, 11, 9));
      expect(await unread(), isFalse);

      repository.messages.add(reply(DateTime(2026, 11, 10)));
      expect(await unread(), isTrue);
    });

    test('返信がない・取得できないときは、お知らせしない', () async {
      await store.markSent();
      expect(await unread(), isFalse);
    });
  });

  group('お問い合わせの画面', () {
    late FakeInquiryRepository repository;
    late MemoryStateStore store;
    late FakePushGateway pushGateway;
    late FakePushTokens pushTokens;

    setUp(() {
      repository = FakeInquiryRepository();
      store = MemoryStateStore();
      pushGateway = FakePushGateway();
      pushTokens = FakePushTokens();
    });

    Widget app() => ProviderScope(
      overrides: [
        inquiryRepositoryProvider.overrideWithValue(repository),
        inquiryStateStoreProvider.overrideWithValue(store),
        pushMessagingGatewayProvider.overrideWithValue(pushGateway),
        pushTokenRepositoryProvider.overrideWithValue(pushTokens),
      ],
      child: const MaterialApp(home: InquiryPage()),
    );

    testWidgets('やり取りがないときは、案内と注意書きを出す', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(find.textContaining('不具合のご報告や、ご要望'), findsOneWidget);
      expect(find.textContaining('個人情報や、日記の内容は、書かないでください'), findsWidgets);
    });

    testWidgets('書くまでは送れず、種類を選んで送ると、一覧に出る', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      FilledButton button() =>
          tester.widget<FilledButton>(find.widgetWithText(FilledButton, '送信'));
      expect(button().onPressed, isNull);

      await tester.tap(find.text('要望'));
      await tester.enterText(find.byKey(const Key('inquiryText')), '  夜のモードが欲しい ');
      await tester.pump();
      expect(button().onPressed, isNotNull);

      await tester.tap(find.widgetWithText(FilledButton, '送信'));
      await tester.pumpAndSettle();

      expect(repository.sent, [(InquiryCategory.request, '夜のモードが欲しい')]);
      expect(store.state.hasSent, isTrue);
      // 送ったので、返信の通知の宛先を登録する
      expect(pushTokens.registered, ['token-1']);
      expect(find.text('夜のモードが欲しい'), findsOneWidget);
      expect(find.text('送信しました。ありがとうございます'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byKey(const Key('inquiryText'))).controller!.text,
        isEmpty,
      );
    });

    testWidgets('開発者の返信が表示され、見たことになる', (tester) async {
      await store.markSent();
      repository.messages.addAll([
        InquiryMessage(
          id: 'u',
          fromDeveloper: false,
          text: '質問です',
          createdAt: DateTime(2026, 11, 9, 9),
          category: InquiryCategory.other,
        ),
        InquiryMessage(
          id: 'd',
          fromDeveloper: true,
          text: '次の更新で直します',
          createdAt: DateTime(2026, 11, 9, 12),
        ),
      ]);

      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(find.text('質問です'), findsOneWidget);
      expect(find.text('次の更新で直します'), findsOneWidget);
      expect(find.text('開発者からの返信'), findsOneWidget);
      expect(find.text('あなた(その他)'), findsOneWidget);

      expect(store.state.seenReplyAt, DateTime(2026, 11, 9, 12));
    });

    testWidgets('送信に失敗したら、理由を出して、書いた内容は残す', (tester) async {
      repository.sendError = const InquiryException(InquiryFailure.tooMany);

      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('inquiryText')), '本文');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, '送信'));
      await tester.pumpAndSettle();

      expect(find.textContaining('送れる件数の上限'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byKey(const Key('inquiryText'))).controller!.text,
        '本文',
      );
    });
  });

  group('AwsPushTokenRepositoryImpl', () {
    test('端末のIDと宛先を送る。成功以外は例外', () async {
      late http.Request request;
      var status = 200;

      final repository = AwsPushTokenRepositoryImpl(
        'https://example.com',
        clientId: () async => 'abc12345',
        client: MockClient((r) async {
          request = r;
          return json(status, {'ok': true});
        }),
      );

      await repository.register('tok');

      expect(request.url.toString(), 'https://example.com/push-token');
      expect(request.method, 'POST');
      expect(request.headers['X-Client-Id'], 'abc12345');
      expect(jsonDecode(request.body), {'token': 'tok'});

      status = 500;
      await expectLater(
        repository.register('tok'),
        throwsA(isA<http.ClientException>()),
      );
    });
  });

  group('PushRegistrar', () {
    late FakePushGateway gateway;
    late FakePushTokens tokens;
    late MemoryStateStore store;
    late int opened;
    late int arrived;
    late PushRegistrar registrar;

    setUp(() {
      gateway = FakePushGateway();
      tokens = FakePushTokens();
      store = MemoryStateStore();
      opened = 0;
      arrived = 0;
      registrar = PushRegistrar(
        gateway: gateway,
        tokens: tokens,
        store: store,
        onOpenInquiry: () => opened++,
        onReplyArrived: () => arrived++,
      );
      addTearDown(registrar.dispose);
    });

    Future<void> settle() => Future<void>.delayed(Duration.zero);

    test('一度も送っていない端末は、宛先を登録しない', () async {
      await registrar.start();
      gateway.refresh.add('new-token');
      await settle();

      expect(tokens.registered, isEmpty);
    });

    test('送ったことがある端末は、起動時に宛先を登録し、宛先が新しくなったら登録し直す', () async {
      await store.markSent();

      await registrar.start();
      expect(tokens.registered, ['token-1']);

      gateway.refresh.add('token-2');
      await settle();
      expect(tokens.registered, ['token-1', 'token-2']);
    });

    test('宛先がない・登録に失敗しても、例外にしない', () async {
      await store.markSent();
      gateway.token = null;
      await registrar.start();
      expect(tokens.registered, isEmpty);

      tokens.fails = true;
      gateway.token = 'token-1';
      await registrar.sync();
      expect(tokens.registered, isEmpty);
    });

    test('通知をタップして開いたとき・起動したときは、お問い合わせを開く', () async {
      gateway.openedFromNotificationAtStart = true;
      await registrar.start();
      expect(opened, 1);

      gateway.opened.add(null);
      await settle();
      expect(opened, 2);
    });

    test('アプリを開いている間に通知が届いたら、表示の更新を求める', () async {
      await registrar.start();

      gateway.foreground.add(null);
      await settle();

      expect(arrived, 1);
      expect(opened, 0);
    });

    test('startを2回呼んでも、1回分だけ動く', () async {
      await store.markSent();
      await registrar.start();
      await registrar.start();

      expect(tokens.registered, ['token-1']);
    });
  });
}
