import '../../../diary_create/domain/entities/photo.dart';
import '../entities/x_archive_post.dart';

/// 投稿に付いていた画像に当たる、端末の写真の候補を探す
///
/// アーカイブの画像は取り込まないので、中身は比べない。次の手がかりで推測する:
/// 投稿の少し前に撮られていること、画像の枚数、縦横比。
/// 間違えることがあるので、利用者があとから変えられる。
class XArchivePhotoMatcher {
  const XArchivePhotoMatcher();

  /// 投稿の何時間前から探すか
  static const lookBefore = Duration(hours: 24);

  /// 投稿の何時間後まで探すか
  static const lookAfter = Duration(hours: 1);

  /// 縦横比のずれの許容(10%なら0.1)
  static const ratioTolerance = 0.1;

  /// 写真を探す期間([from]以上[to]未満)
  ({DateTime from, DateTime to}) window(DateTime postedAt) {
    return (
      from: postedAt.subtract(lookBefore).toLocal(),
      to: postedAt.add(lookAfter).toLocal(),
    );
  }

  /// [candidates] の中から、投稿の画像の枚数ぶんまでを選ぶ(撮影の古い順)
  List<Photo> pick(XArchivePost post, List<Photo> candidates) {
    final count = post.imageFileNames.length;
    if (count == 0 || candidates.isEmpty) return const [];

    // 投稿の日時に近い順に見ていく
    final sorted = [...candidates]..sort((a, b) {
        final da = a.createdAt.difference(post.createdAt).abs();
        final db = b.createdAt.difference(post.createdAt).abs();
        return da.compareTo(db);
      });

    final used = <String>{};
    final picked = <Photo>[];
    for (var i = 0; i < count; i++) {
      final ratio = i < post.imageAspectRatios.length
          ? post.imageAspectRatios[i]
          : 0.0;
      for (final photo in sorted) {
        if (used.contains(photo.id)) continue;
        if (!_ratioMatches(ratio, photo)) continue;
        used.add(photo.id);
        picked.add(photo);
        break;
      }
    }

    picked.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return picked;
  }

  bool _ratioMatches(double ratio, Photo photo) {
    final w = photo.width;
    final h = photo.height;
    // どちらかが分からなければ、縦横比では絞らない
    if (ratio <= 0 || w == null || h == null || w <= 0 || h <= 0) return true;
    final photoRatio = w / h;
    return (photoRatio - ratio).abs() / ratio <= ratioTolerance;
  }
}
