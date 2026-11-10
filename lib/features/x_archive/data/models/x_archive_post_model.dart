import 'package:isar/isar.dart';
part 'x_archive_post_model.g.dart';

/// Xのアーカイブから取り込んだ投稿(「Xから共有」の SharedPostModel とは別)
@collection
class XArchivePostModel {
  Id id = Isar.autoIncrement;

  /// 投稿のID。同じ投稿を2回取り込まないための目印(重複の防止は保存処理で行う)
  @Index()
  late String tweetId;

  late String text;

  /// 投稿した日時(UTC)
  @Index()
  late DateTime createdAt;

  /// XArchivePostKind の名前(post / reply / retweet / quote)
  late String kind;

  String? replyToScreenName;

  /// アーカイブの tweets_media の中の画像のファイル名
  late List<String> imageFileNames;

  /// 画像の縦横比(横÷縦)。imageFileNames と同じ並び。古いデータでは空
  List<double> imageAspectRatios = [];

  late bool hasVideo;

  /// 利用者が選んだ端末の写真のID。nullなら、日時などから探した候補を出す
  List<String>? photoIds;

  XArchivePostModel();
}
