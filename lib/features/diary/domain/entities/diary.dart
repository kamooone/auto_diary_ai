/// 保存した日記
class Diary {
  /// 保存前はnull
  final int? id;

  /// 日記の日付
  final DateTime date;

  final String title;
  final String content;

  /// AIが書いた日記かどうか(falseの場合は自分で書いた日記)
  final bool isAiGenerated;

  /// 日記に添えた写真のID
  final List<String> photoIds;

  final DateTime createdAt;

  const Diary({
    this.id,
    required this.date,
    required this.title,
    required this.content,
    required this.isAiGenerated,
    this.photoIds = const [],
    required this.createdAt,
  });

  /// 一覧などに表示する見出し
  /// タイトルがない場合は、本文の最初の行を使う
  String get headline {
    if (title.trim().isNotEmpty) return title.trim();

    return content.trim().split('\n').first;
  }
}
