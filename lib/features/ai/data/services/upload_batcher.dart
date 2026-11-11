import '../../domain/entities/ai_message_request.dart';

/// 写真を、1回のリクエストが上限に収まるように、いくつかのグループに分ける
///
/// 順番は変えない(アップロード後のS3キーを、元の順につなげるため)。
/// 1枚だけで上限を超える写真があるときは、[onTooLarge]を呼ぶ。
class UploadBatcher {
  UploadBatcher._();

  // JSONの囲み('data'などのキーや記号)の分の、1枚あたりの余裕
  static const _perImageOverhead = 100;

  // 画像以外の部分(message など)の余裕
  static const _baseOverhead = 200;

  /// Base64にしたときの、1枚のリクエスト内での大きさ(バイト)の見積もり
  static int estimateBytes(AiImage image) {
    final base64Length = ((image.bytes.length + 2) ~/ 3) * 4;
    return base64Length + image.contentType.length + _perImageOverhead;
  }

  static List<List<AiImage>> split(
    List<AiImage> images, {
    required int maxBytes,
    required Never Function(int bytes) onTooLarge,
  }) {
    final batches = <List<AiImage>>[];
    var current = <AiImage>[];
    var currentBytes = _baseOverhead;

    for (final image in images) {
      final bytes = estimateBytes(image);

      if (bytes + _baseOverhead > maxBytes) onTooLarge(bytes);

      // 入りきらないときは、ここまでを1つのグループにして、次のグループを始める
      if (current.isNotEmpty && currentBytes + bytes > maxBytes) {
        batches.add(current);
        current = <AiImage>[];
        currentBytes = _baseOverhead;
      }

      current.add(image);
      currentBytes += bytes;
    }

    if (current.isNotEmpty) batches.add(current);
    return batches;
  }
}
