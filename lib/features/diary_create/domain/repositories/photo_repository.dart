import 'dart:typed_data';
import '../entities/photo.dart';

abstract class PhotoRepository {
  /// 端末内の写真を新しい順にページ単位で取得
  /// [from]と[to]を渡すと、その期間([from]以上[to]未満)に撮影された写真だけを取得する
  Future<List<Photo>> getPhotos({
    required int page,
    required int size,
    DateTime? from,
    DateTime? to,
  });

  /// 端末内で、一番古い写真の撮影日時(写真がない場合はnull)
  /// 年の選択肢の範囲を決めるのに使う
  Future<DateTime?> getOldestDate();

  /// 一覧表示用のサムネイルを取得
  Future<Uint8List?> getThumbnail(Photo photo);

  /// 長辺がmaxSide以下になるよう縮小したJPEGを取得
  Future<Uint8List?> getJpeg(
    Photo photo, {
    required int maxSide,
    required int quality,
  });
}
