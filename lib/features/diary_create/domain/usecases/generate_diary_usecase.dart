import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import '../../../ai/domain/entities/ai_message_request.dart';
import '../../../ai/domain/usecases/send_message_usecase.dart';
import '../../../map/domain/entities/location.dart';
import '../../../share/domain/entities/shared_post.dart';

class GenerateDiaryUseCase {
  final SendMessageUseCase _sendMessageUseCase;

  GenerateDiaryUseCase(this._sendMessageUseCase);

  Future<String> execute({
    required String title,
    required String content,
    required DateTime date,
    required List<AssetEntity> photos,
    required List<Location> locations,
    required List<SharedPost> posts,
  }) async {
    final imageFiles = <File>[];
    for (final photo in photos) {
      final file = await photo.file;

      if (file != null) {
        imageFiles.add(file);
      }
    }
    final photoInfoText = photos.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final photo = entry.value;
      return """
      写真 $index枚目
      撮影日時: ${photo.createDateTime}
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
${photos.length}枚添付しています。

写真の撮影日時
$photoInfoText

今日の行動履歴
$locationText

今日のX投稿
$postText

写真の内容だけでなく、撮影日時も考慮して時系列に沿った自然な日記を作成してください。
""",
      images: imageFiles,
    );
    return _sendMessageUseCase.execute(request);
  }
}