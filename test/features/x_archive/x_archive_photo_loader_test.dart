import 'dart:typed_data';

import 'package:auto_diary_ai/features/diary_create/domain/entities/photo.dart';
import 'package:auto_diary_ai/features/diary_create/domain/repositories/photo_repository.dart';
import 'package:auto_diary_ai/features/x_archive/application/services/x_archive_photo_loader.dart';
import 'package:auto_diary_ai/features/x_archive/domain/entities/x_archive_post.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePhotoRepository implements PhotoRepository {
  int calls = 0;

  @override
  Future<List<Photo>> getPhotos({
    required int page,
    required int size,
    DateTime? from,
    DateTime? to,
  }) async {
    calls++;
    return [Photo(id: 'p1', createdAt: DateTime.utc(2026, 5, 1, 2, 50))];
  }

  @override
  Future<DateTime?> getOldestDate() async => null;

  @override
  Future<Uint8List?> getThumbnail(Photo photo) async => null;

  @override
  Future<Uint8List?> getJpeg(Photo photo,
          {required int maxSide, required int quality}) async =>
      null;
}

XArchivePost _post(XArchivePostKind kind) => XArchivePost(
      tweetId: '1',
      text: 't',
      createdAt: DateTime.utc(2026, 5, 1, 3, 0),
      kind: kind,
      imageFileNames: const ['1-a.jpg'],
      imageAspectRatios: const [0],
    );

void main() {
  test('通常の投稿は、近い時間の写真を候補にする', () async {
    final repo = _FakePhotoRepository();
    final photos = await loadXArchivePhotos(_post(XArchivePostKind.post), repo);
    expect(photos.map((p) => p.id), ['p1']);
  });

  test('リツイートの画像は他の人のものなので、探さない', () async {
    final repo = _FakePhotoRepository();
    final photos =
        await loadXArchivePhotos(_post(XArchivePostKind.retweet), repo);
    expect(photos, isEmpty);
    expect(repo.calls, 0);
  });
}
