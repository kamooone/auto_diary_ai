import 'dart:typed_data';

import 'package:auto_diary_ai/features/diary_create/domain/services/jpeg_size.dart';
import 'package:flutter_test/flutter_test.dart';

// 本物のJPEGの代わりに、縦横を読むのに必要な部分だけの、小さなJPEG(ヘッダーのみ)を作る
Uint8List jpegHeader({
  required int width,
  required int height,
  int sofMarker = 0xC0,
  bool withApp0 = true,
  int fillBytes = 0,
}) {
  final bytes = <int>[0xFF, 0xD8];

  if (withApp0) {
    // APP0(長さ16: JFIF)
    bytes.addAll([0xFF, 0xE0, 0x00, 0x10]);
    bytes.addAll([0x4A, 0x46, 0x49, 0x46, 0x00, 0x01, 0x01, 0x00]);
    bytes.addAll([0x00, 0x01, 0x00, 0x01, 0x00, 0x00]);
  }

  // DHT(長さ4)は、縦横ではないので、読み飛ばされる
  bytes.addAll([0xFF, 0xC4, 0x00, 0x04, 0x00, 0x00]);

  bytes.addAll(List.filled(fillBytes, 0xFF));

  // SOF(長さ11: 精度8、高さ、幅、成分数1、成分の情報3)
  bytes.addAll([0xFF, sofMarker, 0x00, 0x0B, 0x08]);
  bytes.addAll([height >> 8, height & 0xFF, width >> 8, width & 0xFF]);
  bytes.addAll([0x01, 0x01, 0x11, 0x00]);

  return Uint8List.fromList(bytes);
}

void main() {
  group('JpegSize.parse', () {
    test('縦長・横長の、縦横を読む', () {
      final landscape = JpegSize.parse(jpegHeader(width: 1024, height: 576));
      expect(landscape?.width, 1024);
      expect(landscape?.height, 576);

      final portrait = JpegSize.parse(jpegHeader(width: 576, height: 1024));
      expect(portrait?.width, 576);
      expect(portrait?.height, 1024);
      expect(portrait.toString(), '576x1024');
    });

    test('APP0がなくても、読める', () {
      final size = JpegSize.parse(jpegHeader(width: 300, height: 200, withApp0: false));
      expect(size?.width, 300);
      expect(size?.height, 200);
    });

    test('プログレッシブ(SOF2)も、読める', () {
      final size = JpegSize.parse(jpegHeader(width: 800, height: 600, sofMarker: 0xC2));
      expect(size?.width, 800);
      expect(size?.height, 600);
    });

    test('マーカーの前の詰め物(FF)は、飛ばす', () {
      final size = JpegSize.parse(jpegHeader(width: 640, height: 480, fillBytes: 3));
      expect(size?.width, 640);
      expect(size?.height, 480);
    });

    test('JPEGでないときや、壊れているときは null', () {
      expect(JpegSize.parse(Uint8List(0)), isNull);
      expect(JpegSize.parse(Uint8List.fromList([1, 2, 3, 4, 5])), isNull);
      // 途中で切れている
      final full = jpegHeader(width: 100, height: 100);
      expect(JpegSize.parse(full.sublist(0, full.length - 8)), isNull);
    });
  });
}
