import '../../../plan/domain/entities/usage_info.dart';

/// AIが書いた日記
class GeneratedDiary {
  /// AIが考えたタイトル(取り出せなかった場合は空文字)
  final String title;

  final String content;

  /// この日記を書いたあとの、今月の使用量(サーバーが返さない場合はnull)
  final UsageInfo? usage;

  const GeneratedDiary({
    required this.title,
    required this.content,
    this.usage,
  });
}
