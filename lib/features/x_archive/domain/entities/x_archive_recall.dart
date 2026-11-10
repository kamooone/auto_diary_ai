import 'x_archive_post.dart';

/// 「N年前の今日」の投稿
class XArchiveRecallYear {
  /// 何年前か
  final int yearsAgo;

  /// その日(日本時間の年月日)
  final DateTime date;

  final List<XArchivePost> posts;

  const XArchiveRecallYear({
    required this.yearsAgo,
    required this.date,
    required this.posts,
  });
}

/// 「過去のツイート紹介」の中身
class XArchiveRecall {
  /// 「N年前の今日」の投稿(近い年が先)
  final List<XArchiveRecallYear> years;

  /// 数が少ないときに足す、ランダムな投稿
  final List<XArchivePost> randoms;

  const XArchiveRecall({this.years = const [], this.randoms = const []});

  bool get isEmpty => years.isEmpty && randoms.isEmpty;
}
