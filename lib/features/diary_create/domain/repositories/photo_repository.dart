import 'dart:typed_data';
import '../entities/photo.dart';
import '../entities/photo_location.dart';

abstract class PhotoRepository {
  /// 端末内の写真を新しい順にページ単位で取得
  /// [from]と[to]を渡すと、その期間([from]以上[to]未満)に撮影された写真だけを取得する
  Future<List<Photo>> getPhotos({
    required int page,
    required int size,
    DateTime? from,
    DateTime? to,
  });

  /// 一覧表示用のサムネイルを取得
  Future<Uint8List?> getThumbnail(Photo photo);

  /// 撮影場所を取得(位置情報が付いていない場合はnull)
  Future<PhotoLocation?> getLocation(Photo photo);

  /// 長辺がmaxSide以下になるよう縮小したJPEGを取得
  Future<Uint8List?> getJpeg(
    Photo photo, {
    required int maxSide,
    required int quality,
  });
}
