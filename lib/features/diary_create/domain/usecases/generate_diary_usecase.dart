import '../../../../core/logging/app_log.dart';
import '../../../ai/domain/entities/ai_message_request.dart';
import '../../../ai/domain/repositories/ai_repository.dart';
import '../../../plan/domain/entities/plan_type.dart';
import '../../../location/domain/entities/timeline_item.dart';
import '../../../share/domain/entities/shared_post.dart';
import '../entities/generated_diary.dart';
import '../entities/photo.dart';
import '../repositories/photo_repository.dart';
import '../services/generated_diary_parser.dart';
import '../entities/diary_style.dart';
import '../services/prompt_spec.dart';
import '../services/timeline_text.dart';

class GenerateDiaryUseCase {
  final AiRepository _aiRepository;
  final PhotoRepository _photoRepository;

  final GeneratedDiaryParser _parser = GeneratedDiaryParser();

  GenerateDiaryUseCase({
    required AiRepository aiRepository,
    required PhotoRepository photoRepository,
  }) : _aiRepository = aiRepository,
       _photoRepository = photoRepository;

  // 送信する画像の長辺サイズ(px)とJPEG品質
  static const _maxImageSide = 1024;
  static const _jpegQuality = 80;

  /// ユーザーが選んだ情報をもとに日記を生成する
  ///
  /// [diaryDate]は日記の日付(何月何日の日記か)
  /// [startDate]と[endDate]は、AIに渡す情報の期間(1日分の場合は同じ日)
  /// [note]はユーザーがAIに追加で伝えたい内容(なければ空文字)
  Future<GeneratedDiary> execute({
    required String note,
    required DateTime diaryDate,
    required DateTime startDate,
    required DateTime endDate,
    required List<Photo> photos,
    required List<TimelineItem> timeline,
    required List<SharedPost> posts,
    PlanType plan = PlanType.free,
    DiaryStyle style = DiaryStyle.diary,
    String customInstruction = '',
    int lengthChars = 0,
  }) async {
    // 撮影時刻順に並べる(選んだ写真は、枚数に関係なくすべて送る)
    final candidates = [...photos]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // 縮小したJPEGに変換する(取得できなかった写真は送らない)
    final sentPhotos = <Photo>[];
    final images = <AiImage>[];
    for (final photo in candidates) {
      final bytes = await AppLog.measure(
        '写真',
        '縮小 ${photo.id}',
        () => _photoRepository.getJpeg(
          photo,
          maxSide: _maxImageSide,
          quality: _jpegQuality,
        ),
      );

      if (bytes != null) {
        sentPhotos.add(photo);
        images.add(AiImage(bytes: bytes, contentType: 'image/jpeg'));
      }
    }

    // 位置情報は「滞在した場所」と「移動」に要約して渡す
    final timelineText = TimelineText.format(timeline);

    final postText = posts
        .map((e) => "${e.receivedAt}\n${e.text}\n${e.url}")
        .join("\n\n");

    // 指示の文章と組み立ては、サーバーが持つ。アプリは、材料と設定だけを送る
    final request = AiMessageRequest(
      plan: plan,
      prompt: PromptSpec.diary(
        style: style,
        customInstruction: customInstruction,
        lengthChars: lengthChars,
        diaryDate: diaryDate,
        startDate: startDate,
        endDate: endDate,
        note: note,
        timelineText: timelineText,
        postsText: postText,
      ),
      images: images,
    );
    final reply = await _aiRepository.sendMessage(request);

    // 回答をタイトルと本文に分ける
    final diary = _parser.parse(reply.answer);

    return GeneratedDiary(
      title: diary.title,
      content: diary.content,
      usage: reply.usage,
      modelName: reply.modelName,
    );
  }
}
