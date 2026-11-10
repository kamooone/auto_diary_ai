import '../entities/x_archive_post.dart';

/// 「過去のツイート紹介」に出してよい投稿か
///
/// 自分の通常の投稿と引用だけ。リツイートは他の人の言葉、リプライは相手の発言が
/// 分からず意味が通じにくいので除く。短すぎる投稿(あいさつなど)も除く。
bool isXArchiveRecallEligible(XArchivePost post) {
  if (post.kind != XArchivePostKind.post &&
      post.kind != XArchivePostKind.quote) {
    return false;
  }
  return post.text.trim().length >= xArchiveRecallMinTextLength;
}

/// 紹介に出す投稿の、本文の最低の長さ
const xArchiveRecallMinTextLength = 8;
