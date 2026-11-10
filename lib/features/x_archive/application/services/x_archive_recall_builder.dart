import 'dart:math';

import '../../domain/entities/x_archive_post.dart';
import '../../domain/entities/x_archive_post_filter.dart';
import '../../domain/entities/x_archive_recall.dart';
import '../../domain/repositories/x_archive_repository.dart';
import '../../domain/services/x_archive_recall_rules.dart';

/// 「過去のツイート紹介」の中身を作る
///
/// 今日と同じ月日の投稿を、1年前、2年前…と集める。全体の数が少ないときは、
/// ランダムな投稿を足す。ランダムは日付から決めるので、同じ日なら何度開いても同じ。
class XArchiveRecallBuilder {
  final XArchiveRepository repository;

  const XArchiveRecallBuilder(this.repository);

  /// 1つの年から出す投稿の上限
  static const perYearMax = 5;

  /// 「N年前の今日」の投稿の合計の上限
  static const totalMax = 20;

  /// 全体がこれより少ないときに、ランダムな投稿を足す
  static const minTotal = 5;

  /// 日本時間の [today] (年月日だけを使う)の紹介を作る
  Future<XArchiveRecall> build(DateTime today) async {
    final counts = await repository.countByYear();
    if (counts.isEmpty) return const XArchiveRecall();

    final oldest = counts.keys.reduce(min);
    final years = <XArchiveRecallYear>[];
    final usedIds = <String>{};
    var total = 0;

    for (var ago = 1; today.year - ago >= oldest && total < totalMax; ago++) {
      final year = today.year - ago;
      // うるう日(2月29日)は、その日がない年を飛ばす
      if (today.day > XArchivePostFilter.daysInMonth(year, today.month)) {
        continue;
      }

      final posts = await repository.findPage(
        offset: 0,
        limit: 200,
        filter: XArchivePostFilter(
          year: year,
          month: today.month,
          day: today.day,
        ),
      );
      final eligible = posts.where(isXArchiveRecallEligible).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final room = min(perYearMax, totalMax - total);
      final picked = eligible.take(room).toList();
      if (picked.isEmpty) continue;

      years.add(XArchiveRecallYear(
        yearsAgo: ago,
        date: DateTime(year, today.month, today.day),
        posts: picked,
      ));
      usedIds.addAll(picked.map((p) => p.tweetId));
      total += picked.length;
    }

    return XArchiveRecall(
      years: years,
      randoms: await _randoms(today, need: minTotal - total, usedIds: usedIds),
    );
  }

  Future<List<XArchivePost>> _randoms(
    DateTime today, {
    required int need,
    required Set<String> usedIds,
  }) async {
    if (need <= 0) return const [];
    final count = await repository.countOriginals();
    if (count == 0) return const [];

    // 日付から決める。同じ日なら、何度開いても同じ投稿になる
    final random = Random(today.year * 10000 + today.month * 100 + today.day);
    final picked = <XArchivePost>[];
    final ids = {...usedIds};
    // 短い投稿などに当たることがあるので、多めに試す(無限には試さない)
    for (var i = 0; i < need * 8 && picked.length < need; i++) {
      final found = await repository.findOriginals(
        offset: random.nextInt(count),
        limit: 1,
      );
      if (found.isEmpty) continue;
      final post = found.first;
      if (!isXArchiveRecallEligible(post) || !ids.add(post.tweetId)) continue;
      picked.add(post);
    }
    return picked;
  }
}
