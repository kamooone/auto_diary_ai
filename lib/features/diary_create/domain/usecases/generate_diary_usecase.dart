import '../../../ai/domain/entities/ai_message_request.dart';
import '../../../ai/domain/usecases/send_message_usecase.dart';
import '../../../location/domain/entities/timeline_item.dart';
import '../../../location/domain/repositories/place_name_repository.dart';
import '../../../share/domain/entities/shared_post.dart';
import '../entities/photo.dart';
import '../repositories/photo_repository.dart';

class GenerateDiaryUseCase {
  final SendMessageUseCase _sendMessageUseCase;
  final PhotoRepository _photoRepository;
  final PlaceNameRepository _placeNameRepository;

  GenerateDiaryUseCase(
    this._sendMessageUseCase,
    this._photoRepository,
    this._placeNameRepository,
  );

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
    required List<TimelineItem> timeline,
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

    // 撮影場所が分かる写真は、位置履歴が欠けた時間帯の手がかりになる
    final photoInfos = <String>[];
    for (final (index, photo) in sentPhotos.indexed) {
      final place = await _photoPlace(photo);

      photoInfos.add("""
      写真 ${index + 1}枚目
      撮影日時: ${photo.createdAt}${place == null ? "" : "\n      撮影場所: $place"}
      """);
    }
    final photoInfoText = photoInfos.join("\n");

    // 位置情報は「滞在した場所」と「移動」に要約して渡す
    final timelineText = timeline.map((e) {
      final time = "${_time(e.start)}〜${_time(e.end)}";

      return switch (e) {
        Stay() => "$time 滞在: ${e.placeName ?? "緯度${e.latitude.toStringAsFixed(4)} 経度${e.longitude.toStringAsFixed(4)}付近"}",
        Move() => "$time 移動: 約${_distance(e.distanceMeters)}",
      };
    }).join("\n");

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

写真の撮影日時と撮影場所
$photoInfoText

今日の行動履歴(滞在した場所と移動)
$timelineText

今日のX投稿
$postText

写真の内容だけでなく、撮影日時・撮影場所と行動履歴も照らし合わせて、時系列に沿った自然な日記を作成してください。
""",
      images: images,
    );
    return _sendMessageUseCase.execute(request);
  }

  // 写真の撮影場所(位置情報が付いていない場合はnull)
  Future<String?> _photoPlace(Photo photo) async {
    final location = await _photoRepository.getLocation(photo);
    if (location == null) return null;

    final placeName = await _placeNameRepository.getPlaceName(
      location.latitude,
      location.longitude,
    );

    return placeName ??
        "緯度${location.latitude.toStringAsFixed(4)} 経度${location.longitude.toStringAsFixed(4)}付近";
  }

  String _time(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  String _distance(double meters) {
    return meters >= 1000
        ? "${(meters / 1000).toStringAsFixed(1)}km"
        : "${meters.round()}m";
  }

  List<Photo> _pickEvenly(List<Photo> photos, int max) {
    if (photos.length <= max) return photos;

    final step = (photos.length - 1) / (max - 1);
    return [
      for (var i = 0; i < max; i++) photos[(i * step).round()],
    ];
  }
}
