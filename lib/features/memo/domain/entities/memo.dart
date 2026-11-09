/// ひとことメモ(その日のできごとや気持ちを、短く残したもの)
class Memo {
  /// 保存済みのメモを特定するID(保存前はnull)
  final int? id;

  final String text;

  /// メモの日時(追加した時刻。あとから修正できる)
  final DateTime createdAt;

  /// メモに添えた写真のID(端末の写真を参照する)
  final List<String> photoIds;

  /// メモの文字数の上限
  static const maxLength = 280;

  const Memo({
    this.id,
    required this.text,
    required this.createdAt,
    this.photoIds = const [],
  });
}
