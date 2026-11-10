import '../../domain/entities/x_archive_post.dart';

/// 投稿の日時や種類を、画面に出す文字にする
class XArchivePostFormatter {
  const XArchivePostFormatter._();

  static String kindLabel(XArchivePost post) {
    switch (post.kind) {
      case XArchivePostKind.post:
        return '';
      case XArchivePostKind.reply:
        final to = post.replyToScreenName;
        return to == null ? 'リプライ' : '@$to へのリプライ';
      case XArchivePostKind.retweet:
        return 'リツイート';
      case XArchivePostKind.quote:
        return '引用';
    }
  }

  /// 日本時間の日時
  static String date(DateTime utc) {
    final t = utc.add(const Duration(hours: 9));
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}/${two(t.month)}/${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
  }

  /// 種類・画像の枚数・動画の有無
  static List<String> notes(XArchivePost post) {
    final kind = kindLabel(post);
    return [
      if (kind.isNotEmpty) kind,
      if (post.imageFileNames.isNotEmpty) '画像${post.imageFileNames.length}枚',
      if (post.hasVideo) '動画あり',
    ];
  }
}
