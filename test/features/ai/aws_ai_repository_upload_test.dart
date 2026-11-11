import 'dart:convert';
import 'dart:typed_data';

import 'package:auto_diary_ai/features/ai/data/repositories/aws_ai_repository_impl.dart';
import 'package:auto_diary_ai/features/ai/domain/entities/ai_message_request.dart';
import 'package:auto_diary_ai/features/ai/domain/exceptions/ai_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response jsonResponse(int status, Map<String, dynamic> body) =>
    http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

AiImage image(int size, int fill) => AiImage(
  bytes: Uint8List(size)..fillRange(0, size, fill),
  contentType: 'image/jpeg',
);

void main() {
  group('写真のアップロード', () {
    test('合計が上限を超えても、分けて送り、キーを元の順につなげてチャットに渡す', () async {
      final uploadBodies = <int>[];
      var counter = 0;
      List<dynamic>? chatImages;

      final repository = AwsAiRepositoryImpl(
        'https://example.com',
        client: MockClient((http.Request r) async {
          if (r.url.path == '/ai/upload-url') {
            final images = jsonDecode(r.body)['images'] as List;
            uploadBodies.add(r.bodyBytes.length);
            return jsonResponse(200, {
              'images': [for (final _ in images) 'key-${counter++}'],
            });
          }
          chatImages = jsonDecode(r.body)['images'] as List;
          return jsonResponse(200, {'answer': 'ok'});
        }),
      );

      // 1枚あたり約1.3MB(Base64後)を6枚 = 約8MB。1回の上限(5MB)を超える
      final images = [for (var i = 0; i < 6; i++) image(1000 * 1000, i)];

      await repository.sendMessage(
        AiMessageRequest(prompt: const {'kind': 'test'}, images: images),
      );

      expect(uploadBodies.length, greaterThan(1));
      for (final bytes in uploadBodies) {
        expect(bytes, lessThanOrEqualTo(5 * 1024 * 1024));
      }
      expect(chatImages, [for (var i = 0; i < 6; i++) 'key-$i']);
    });

    test('1枚だけで上限を超える写真は、アップロードの失敗にする', () async {
      final repository = AwsAiRepositoryImpl(
        'https://example.com',
        client: MockClient((_) async => jsonResponse(200, {'answer': 'ok'})),
      );

      expect(
        () => repository.sendMessage(
          AiMessageRequest(
            prompt: const {'kind': 'test'},
            images: [image(5 * 1024 * 1024, 1)],
          ),
        ),
        throwsA(isA<AiUploadException>()),
      );
    });

    test('途中のグループが失敗したら、アップロードの失敗にする', () async {
      var calls = 0;
      final repository = AwsAiRepositoryImpl(
        'https://example.com',
        client: MockClient((http.Request r) async {
          calls++;
          if (calls == 2) return http.Response('error', 500);
          final images = jsonDecode(r.body)['images'] as List;
          return jsonResponse(200, {
            'images': [for (final _ in images) 'k'],
          });
        }),
      );

      expect(
        () => repository.sendMessage(
          AiMessageRequest(
            prompt: const {'kind': 'test'},
            images: [for (var i = 0; i < 6; i++) image(1000 * 1000, i)],
          ),
        ),
        throwsA(isA<AiUploadException>()),
      );
    });
  });
}
