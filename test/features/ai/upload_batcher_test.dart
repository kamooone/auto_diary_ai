import 'dart:typed_data';

import 'package:auto_diary_ai/features/ai/data/services/upload_batcher.dart';
import 'package:auto_diary_ai/features/ai/domain/entities/ai_message_request.dart';
import 'package:flutter_test/flutter_test.dart';

AiImage image(int size, [int fill = 0]) => AiImage(
  bytes: Uint8List(size)..fillRange(0, size, fill),
  contentType: 'image/jpeg',
);

Never tooLarge(int bytes) => throw StateError('too large: $bytes');

void main() {
  group('UploadBatcher.split', () {
    test('写真がなければ、グループもない', () {
      expect(
        UploadBatcher.split(const [], maxBytes: 1000, onTooLarge: tooLarge),
        isEmpty,
      );
    });

    test('上限に収まるなら、1グループにまとめる', () {
      final images = [image(100), image(100), image(100)];
      final batches = UploadBatcher.split(
        images,
        maxBytes: 5 * 1024 * 1024,
        onTooLarge: tooLarge,
      );
      expect(batches.length, 1);
      expect(batches.single.length, 3);
    });

    test('上限を超えるときは、順番を保ったまま分ける', () {
      // 1枚の見積もりは、約1400バイト
      final images = [for (var i = 0; i < 10; i++) image(1000, i)];
      final one = UploadBatcher.estimateBytes(images.first);

      final batches = UploadBatcher.split(
        images,
        maxBytes: one * 3 + 300,
        onTooLarge: tooLarge,
      );

      expect(batches.map((e) => e.length), [3, 3, 3, 1]);
      // 元の順番のまま
      final flat = batches.expand((e) => e).toList();
      expect([for (final e in flat) e.bytes.first], [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
    });

    test('どのグループも、上限を超えない', () {
      final images = [for (var i = 0; i < 60; i++) image(250 * 1024)];
      const max = 5 * 1024 * 1024;
      final batches = UploadBatcher.split(
        images,
        maxBytes: max,
        onTooLarge: tooLarge,
      );
      expect(batches.length, greaterThan(1));
      for (final batch in batches) {
        final total = batch.fold<int>(0, (a, e) => a + UploadBatcher.estimateBytes(e));
        expect(total, lessThanOrEqualTo(max));
      }
      expect(batches.fold<int>(0, (a, e) => a + e.length), 60);
    });

    test('1枚だけで上限を超える写真は、断る', () {
      expect(
        () => UploadBatcher.split(
          [image(5000)],
          maxBytes: 1000,
          onTooLarge: tooLarge,
        ),
        throwsStateError,
      );
    });
  });
}
