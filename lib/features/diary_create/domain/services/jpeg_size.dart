import 'dart:typed_data';

/// JPEGの縦横のピクセル数(画像を開かずに、ヘッダーから読む)
class JpegSize {
  final int width;
  final int height;

  const JpegSize(this.width, this.height);

  @override
  String toString() => '${width}x$height';

  /// 読み取れないとき(JPEGでない、壊れているなど)は null
  static JpegSize? parse(Uint8List bytes) {
    // 先頭は SOI(FF D8)
    if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) return null;

    var i = 2;
    while (i + 3 < bytes.length) {
      // マーカーは FF で始まる(FF が続くときは、詰め物なので飛ばす)
      if (bytes[i] != 0xFF) return null;
      while (i < bytes.length && bytes[i] == 0xFF) {
        i++;
      }
      if (i >= bytes.length) return null;

      final marker = bytes[i];
      i++;

      // 長さのないマーカー(SOI・EOI・RSTn・TEM)
      if (marker == 0xD8 || marker == 0x01 || (marker >= 0xD0 && marker <= 0xD7)) {
        continue;
      }
      if (marker == 0xD9) return null;

      if (i + 1 >= bytes.length) return null;
      final length = (bytes[i] << 8) | bytes[i + 1];
      if (length < 2) return null;

      // SOF(C0〜CF。ただし C4=DHT・C8=JPG・CC=DAC は違う)に、縦横が入っている
      final isSof = marker >= 0xC0 &&
          marker <= 0xCF &&
          marker != 0xC4 &&
          marker != 0xC8 &&
          marker != 0xCC;
      if (isSof) {
        // 長さ(2)・精度(1)・高さ(2)・幅(2)
        if (i + 6 >= bytes.length) return null;
        final height = (bytes[i + 3] << 8) | bytes[i + 4];
        final width = (bytes[i + 5] << 8) | bytes[i + 6];
        if (width == 0 || height == 0) return null;
        return JpegSize(width, height);
      }

      i += length;
    }
    return null;
  }
}
