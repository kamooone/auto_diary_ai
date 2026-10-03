import 'dart:typed_data';
import '../entities/photo.dart';

abstract class PhotoRepository {
  /// 端末内の写真を新しい順にページ単位で取得
  Future<List<Photo>> getPhotos({
    required int page,
    required int size,
  });

  /// 一覧表示用のサムネイルを取得
  Future<Uint8List?> getThumbnail(Photo photo);

  /// 長辺がmaxSide以下になるよう縮小したJPEGを取得
  Future<Uint8List?> getJpeg(
    Photo photo, {
    required int maxSide,
    required int quality,
  });
}
