/// Xのアーカイブから取り込んだ投稿の種類
enum XArchivePostKind {
  /// 自分の通常の投稿
  post,

  /// 自分の投稿への、または他の人へのリプライ
  reply,

  /// リツイート(本文は前半だけが入っている)
  retweet,

  /// 引用リツイート(引用元の内容は入っていない。URLだけ)
  quote,
}

/// Xのアーカイブ(tweets.js)の1件分。保存前の形
class XArchivePost {
  /// 投稿のID(重複の判定に使う)
  final String tweetId;

  /// 本文(HTMLの記号は戻し、画像のURLは取り除いた状態)
  final String text;

  /// 投稿した日時(UTC)
  final DateTime createdAt;

  final XArchivePostKind kind;

  /// リプライ先のID名(@の後ろ)。リプライでないときはnull
  final String? replyToScreenName;

  /// 画像のファイル名(アーカイブの tweets_media の中の名前)。動画は含まない
  final List<String> imageFileNames;

  /// 画像の縦横比(横÷縦)。[imageFileNames]と同じ並び。分からないものは0
  final List<double> imageAspectRatios;

  /// 動画やGIFが付いているか(今は取り込まない)
  final bool hasVideo;

  /// 利用者が選んだ端末の写真のID。nullなら、日時などから探した候補を出す
  final List<String>? photoIds;

  const XArchivePost({
    required this.tweetId,
    required this.text,
    required this.createdAt,
    required this.kind,
    this.replyToScreenName,
    this.imageFileNames = const [],
    this.imageAspectRatios = const [],
    this.hasVideo = false,
    this.photoIds,
  });

  /// 投稿のURL。ユーザー名が分からなくても開ける形
  String get url => 'https://x.com/i/status/$tweetId';
}
