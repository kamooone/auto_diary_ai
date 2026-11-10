import '../../../diary_create/domain/entities/photo.dart';
import '../../../diary_create/domain/repositories/photo_repository.dart';
import '../../domain/entities/x_archive_post.dart';
import '../../domain/services/x_archive_photo_matcher.dart';

/// 投稿に結びつける端末の写真を決める
///
/// 利用者が選んだ写真があればそれを、なければ日時などから探した候補を返す。
/// 写真を読めない(許可がないなど)ときは、空にする。
Future<List<Photo>> loadXArchivePhotos(
  XArchivePost post,
  PhotoRepository photoRepository, {
  XArchivePhotoMatcher matcher = const XArchivePhotoMatcher(),
}) async {
  final chosen = post.photoIds;
  if (chosen != null) {
    return [
      for (final id in chosen) Photo(id: id, createdAt: post.createdAt),
    ];
  }
  // リツイートの画像は他の人のもので、端末にはない
  if (post.kind == XArchivePostKind.retweet) return const [];
  if (post.imageFileNames.isEmpty) return const [];

  try {
    final range = matcher.window(post.createdAt);
    final candidates = await photoRepository.getPhotos(
      page: 0,
      size: 100,
      from: range.from,
      to: range.to,
    );
    return matcher.pick(post, candidates);
  } catch (_) {
    return const [];
  }
}
