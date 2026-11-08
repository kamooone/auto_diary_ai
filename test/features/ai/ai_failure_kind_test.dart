import 'dart:async';
import 'dart:convert';
import 'package:auto_diary_ai/features/ai/data/repositories/aws_ai_repository_impl.dart';
import 'package:auto_diary_ai/features/ai/domain/entities/ai_message_request.dart';
import 'package:auto_diary_ai/features/ai/domain/exceptions/ai_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response json(int status, Object body) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  const request = AiMessageRequest(message: 'こんにちは');

  Future<Object?> failureOf(http.Response response) async {
    final repository = AwsAiRepositoryImpl(
      'https://example.com',
      client: MockClient((_) async => response),
    );

    try {
      await repository.sendMessage(request);
    } catch (e) {
      return e;
    }
    return null;
  }

  group('日記の生成の失敗の種類', () {
    test('AI側が混んでいるときの502は、混雑', () async {
      final e = await failureOf(
        json(502, {
          'error': 'Gemini API request failed',
          'details': '{"error":{"code":503,"status":"UNAVAILABLE"}}',
        }),
      );

      expect(e, isA<AiBusyException>());
    });

    test('サーバーがAIを待ちきれなかった502(timed out)は、時間切れ', () async {
      final e = await failureOf(
        json(502, {
          'error': 'Gemini API request failed',
          'details': 'The read operation timed out',
        }),
      );

      expect(e, isA<AiTimeoutException>());
    });

    test('API Gatewayの504は、時間切れ', () async {
      expect(
        await failureOf(json(504, {'message': 'Endpoint request timed out'})),
        isA<AiTimeoutException>(),
      );
    });

    test('アプリが待つ時間を超えたときは、時間切れ', () async {
      final repository = AwsAiRepositoryImpl(
        'https://example.com',
        client: MockClient((_) async => throw TimeoutException('t')),
      );

      await expectLater(
        repository.sendMessage(request),
        throwsA(isA<AiTimeoutException>()),
      );
    });

    test('そのほかの失敗は、これまでどおり', () async {
      expect(
        await failureOf(json(500, {'error': 'x'})),
        isA<AiChatException>(),
      );
    });
  });

  group('予備のモデルの設定をサーバーに送る', () {
    Future<Map<String, dynamic>> sentBody({bool? fallback}) async {
      late Map<String, dynamic> body;

      final repository = AwsAiRepositoryImpl(
        'https://example.com',
        client: MockClient((req) async {
          body = jsonDecode(req.body) as Map<String, dynamic>;
          return json(200, {'answer': '回答'});
        }),
        geminiFallback: fallback == null ? null : () => fallback,
      );

      await repository.sendMessage(request);
      return body;
    }

    test('オンのときだけ、geminiFallbackを送る', () async {
      expect((await sentBody(fallback: true))['geminiFallback'], isTrue);
    });

    test('オフのときや、設定がないときは、送らない', () async {
      expect((await sentBody(fallback: false)).containsKey('geminiFallback'),
          isFalse);
      expect((await sentBody()).containsKey('geminiFallback'), isFalse);
    });
  });

  group('日記を書いたモデルの名前', () {
    Future<String?> modelNameOf(Map<String, Object?> body) async {
      final repository = AwsAiRepositoryImpl(
        'https://example.com',
        client: MockClient((_) async => json(200, body)),
      );

      return (await repository.sendMessage(request)).modelName;
    }

    test('サーバーが返したら、その名前を持つ', () async {
      expect(
        await modelNameOf({'answer': '回答', 'usedModel': 'gpt-5-mini'}),
        'gpt-5-mini',
      );
    });

    test('返さないときや、空のときは、null', () async {
      expect(await modelNameOf({'answer': '回答'}), isNull);
      expect(await modelNameOf({'answer': '回答', 'usedModel': ''}), isNull);
      expect(await modelNameOf({'answer': '回答', 'usedModel': 1}), isNull);
    });
  });
}
