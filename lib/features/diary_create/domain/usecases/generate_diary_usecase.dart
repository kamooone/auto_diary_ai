import 'package:photo_manager/photo_manager.dart';
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
    final photoText = photos
        .map((e) => "${e.title} (${e.createDateTime})")
        .join("\n");

    final locationText = locations
        .map((e) =>
    "${e.timestamp} 緯度:${e.latitude} 経度:${e.longitude}")
        .join("\n");

    final postText = posts
        .map((e) =>
    "${e.receivedAt}\n${e.text}\n${e.url}")
        .join("\n\n");

    final input = """
    タイトル: $title
    本文: $content
    日付: $date
    今日の写真: $photoText
    今日の行動履歴: $locationText
    今日のX投稿: $postText
    """;

    return _sendMessageUseCase.execute(
      """
      あなたは優秀な日記作成AIです。
      以下の情報を参考に、自然な日記を書いてください。
      $input
      """,
    );
  }
}