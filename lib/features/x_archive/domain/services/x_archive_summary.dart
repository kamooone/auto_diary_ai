import '../entities/x_archive_post.dart';

/// 日本時間での年(投稿日時はUTCで持っているので、9時間足して数える)
int xArchiveYearJst(DateTime createdAtUtc) {
  return createdAtUtc.add(const Duration(hours: 9)).year;
}

/// 取り込む前に見せる、年ごとの件数
Map<int, int> countByYear(Iterable<XArchivePost> posts) {
  final counts = <int, int>{};
  for (final post in posts) {
    final year = xArchiveYearJst(post.createdAt);
    counts[year] = (counts[year] ?? 0) + 1;
  }
  return counts;
}

/// 選んだ年の投稿だけを返す
List<XArchivePost> filterByYears(
  Iterable<XArchivePost> posts,
  Set<int> years,
) {
  return posts
      .where((p) => years.contains(xArchiveYearJst(p.createdAt)))
      .toList();
}

/// 投稿のうち、いちばん古いものの日(日本時間の0時)。投稿がなければnull
DateTime? oldestPostDayJst(Iterable<XArchivePost> posts) {
  DateTime? oldest;
  for (final post in posts) {
    if (oldest == null || post.createdAt.isBefore(oldest)) {
      oldest = post.createdAt;
    }
  }
  if (oldest == null) return null;

  final jst = oldest.add(const Duration(hours: 9));
  return DateTime(jst.year, jst.month, jst.day);
}
