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
import '../services/timeline_text.dart';
import '../services/writing_style.dart';

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
    String writingStyle = WritingStyle.defaultText,
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

    final request = AiMessageRequest(
      plan: plan,
      message:
          """
あなたは優秀な日記作成AIです。

添付した写真も必ず確認し、
写真から読み取れる内容も日記に反映してください。

以下の情報を参考に、自然な日記と、その内容に合ったタイトルを書いてください。

ユーザーが追加で伝えたいこと
${note.trim().isEmpty ? "(なし)" : note.trim()}
${WritingStyle.section(writingStyle)}
日記の日付
${_period(diaryDate, diaryDate)}
${_isSameDay(startDate, endDate) && _isSameDay(startDate, diaryDate) ? "" : "\n渡した情報の期間\n${_period(startDate, endDate)}\n"}
写真
${sentPhotos.length}枚添付しています。

行動履歴(滞在した場所と移動)
※「推定」と付いた場所や移動手段は、位置情報から自動で推定したものです。
$timelineText

Xの投稿
$postText

写真の内容と行動履歴も照らし合わせて、時系列に沿った自然な日記を作成してください。

回答は必ず次の形式で書いてください。前置きや説明、記号による装飾は付けないでください。

タイトル: (日記のタイトルを1行で)
本文:
(日記の本文)
""",
      images: images,
    );
    final reply = await _aiRepository.sendMessage(request);

    // 回答をタイトルと本文に分ける
    final diary = _parser.parse(reply.answer);

    return GeneratedDiary(
      title: diary.title,
      content: diary.content,
      usage: reply.usage,
    );
  }

  String _period(DateTime start, DateTime end) {
    String date(DateTime d) => "${d.year}年${d.month}月${d.day}日";

    final isSameDay =
        start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;

    return isSameDay ? date(start) : "${date(start)}〜${date(end)}";
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
