import '../../../share/domain/entities/shared_post.dart';
import '../../../x_archive/domain/entities/x_archive_post.dart';

/// 取り込んだXの投稿を、AIに渡す投稿として選べる形にする
class ArchivePostSource {
  const ArchivePostSource._();

  static const _jst = Duration(hours: 9);

  /// [startDay]から[endDay]までの、日本時間の範囲(UTC。終わりは含まない)
  static ({DateTime from, DateTime to}) rangeJst(
    DateTime startDay,
    DateTime endDay,
  ) {
    return (
      from: DateTime.utc(
        startDay.year,
        startDay.month,
        startDay.day,
      ).subtract(_jst),
      to: DateTime.utc(
        endDay.year,
        endDay.month,
        endDay.day + 1,
      ).subtract(_jst),
    );
  }

  /// 日付は、日本時間の日時にする(選ぶ画面で、日ごとに分けるため)
  static SharedPost toPost(XArchivePost post) {
    final jst = post.createdAt.add(_jst);
    return SharedPost(
      url: post.url,
      text: post.text,
      receivedAt: DateTime(
        jst.year,
        jst.month,
        jst.day,
        jst.hour,
        jst.minute,
        jst.second,
      ),
    );
  }
}
