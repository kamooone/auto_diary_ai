import '../../../ai/domain/entities/ai_message_request.dart';
import '../../../ai/domain/usecases/send_message_usecase.dart';
import '../../../location/domain/entities/location.dart';
import '../../../share/domain/entities/shared_post.dart';
import '../entities/photo.dart';
import '../repositories/photo_repository.dart';

class GenerateDiaryUseCase {
  final SendMessageUseCase _sendMessageUseCase;
  final PhotoRepository _photoRepository;

  GenerateDiaryUseCase(this._sendMessageUseCase, this._photoRepository);

  // AIへ送る写真の上限枚数
  static const maxPhotos = 10;

  // 送信する画像の長辺サイズ(px)とJPEG品質
  static const _maxImageSide = 1024;
  static const _jpegQuality = 80;

  Future<String> execute({
    required String title,
    required String content,
    required DateTime date,
    required List<Photo> photos,
    required List<Location> locations,
    required List<SharedPost> posts,
  }) async {
    // 撮影時刻順に並べ、上限を超える場合は1日全体から均等に間引く
    final sortedPhotos = [...photos]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final candidates = _pickEvenly(sortedPhotos, maxPhotos);

    // 縮小したJPEGに変換する(取得できなかった写真は送らない)
    final sentPhotos = <Photo>[];
    final images = <AiImage>[];
    for (final photo in candidates) {
      final bytes = await _photoRepository.getJpeg(
        photo,
        maxSide: _maxImageSide,
        quality: _jpegQuality,
      );

      if (bytes != null) {
        sentPhotos.add(photo);
        images.add(AiImage(bytes: bytes, contentType: 'image/jpeg'));
      }
    }

    final photoInfoText = sentPhotos.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final photo = entry.value;
      return """
      写真 $index枚目
      撮影日時: ${photo.createdAt}
      """;
    }).join("\n");

    final locationText = locations
        .map((e) =>
    "${e.timestamp} 緯度:${e.latitude} 経度:${e.longitude}")
        .join("\n");

    final postText = posts
        .map((e) =>
    "${e.receivedAt}\n${e.text}\n${e.url}")
        .join("\n\n");

    final request = AiMessageRequest(
      message: """
あなたは優秀な日記作成AIです。

添付した写真も必ず確認し、
写真から読み取れる内容も日記に反映してください。

以下の情報を参考に自然な日記を書いてください。

タイトル
$title

本文
$content

日付
$date

写真
${sentPhotos.length}枚添付しています。

写真の撮影日時
$photoInfoText

今日の行動履歴
$locationText

今日のX投稿
$postText

写真の内容だけでなく、撮影日時も考慮して時系列に沿った自然な日記を作成してください。
""",
      images: images,
    );
    return _sendMessageUseCase.execute(request);
  }

  List<Photo> _pickEvenly(List<Photo> photos, int max) {
    if (photos.length <= max) return photos;

    final step = (photos.length - 1) / (max - 1);
    return [
      for (var i = 0; i < max; i++) photos[(i * step).round()],
    ];
  }
}
