import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../../core/logging/app_log.dart';
import '../../domain/entities/photo.dart';
import '../../domain/exceptions/photo_exception.dart';
import '../../domain/repositories/photo_repository.dart';

class PhotoRepositoryImpl implements PhotoRepository {
  static const _thumbnailSide = 200;

  // 縮小が終わらない写真(10MBを超えるものなど)で、いつまでも待たないための時間
  static const _jpegTimeout = Duration(seconds: 20);

  // 取得済みのAssetEntityをidから引けるように保持する
  final _assets = <String, AssetEntity>{};

  @override
  Future<List<Photo>> getPhotos({
    required int page,
    required int size,
    DateTime? from,
    DateTime? to,
  }) async {
    final permission = await PhotoManager.requestPermissionExtend();

    if (!permission.hasAccess) {
      throw PhotoPermissionException();
    }

    final filter = FilterOptionGroup(
      // 終了日時ちょうどの写真は含めない
      createTimeCond: from != null && to != null
          ? DateTimeCond(
              min: from,
              max: to.subtract(const Duration(seconds: 1)),
            )
          : null,
      orders: [
        const OrderOption(
          type: OrderOptionType.createDate,
          asc: false,
        ),
      ],
    );

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
      filterOption: filter,
    );

    if (albums.isEmpty) return [];

    final assets = await albums.first.getAssetListPaged(
      page: page,
      size: size,
    );

    return assets.map((asset) {
      _assets[asset.id] = asset;

      return Photo(
        id: asset.id,
        createdAt: asset.createDateTime,
        width: asset.orientatedWidth,
        height: asset.orientatedHeight,
      );
    }).toList();
  }

  @override
  Future<DateTime?> getOldestDate() async {
    final permission = await PhotoManager.requestPermissionExtend();

    if (!permission.hasAccess) {
      throw PhotoPermissionException();
    }

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
      filterOption: FilterOptionGroup(
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: true),
        ],
      ),
    );

    if (albums.isEmpty) return null;

    final assets = await albums.first.getAssetListRange(start: 0, end: 1);

    return assets.isEmpty ? null : assets.first.createDateTime;
  }

  @override
  Future<Uint8List?> getThumbnail(Photo photo) async {
    final asset = await _findAsset(photo.id);

    return asset?.thumbnailDataWithSize(
      const ThumbnailSize.square(_thumbnailSide),
    );
  }

  @override
  Future<Uint8List?> getJpeg(
    Photo photo, {
    required int maxSide,
    required int quality,
  }) async {
    final asset = await _findAsset(photo.id);
    if (asset == null) return null;

    // 時間内に縮小できなければ、半分の大きさで試し直す
    for (final side in [maxSide, maxSide ~/ 2]) {
      try {
        final bytes = await asset
            .thumbnailDataWithSize(
              fitSize(
                asset.orientatedWidth,
                asset.orientatedHeight,
                side,
              ),
              format: ThumbnailFormat.jpeg,
              quality: quality,
            )
            .timeout(_jpegTimeout);

        if (bytes != null) return bytes;
      } on TimeoutException {
        AppLog.add(
          '写真',
          '縮小が${_jpegTimeout.inSeconds}秒で終わらない: '
              '${asset.width}x${asset.height} 長辺$side',
        );
      }
    }

    return null;
  }

  Future<AssetEntity?> _findAsset(String id) async {
    return _assets[id] ?? await AssetEntity.fromId(id);
  }

  /// 縦横比を保ったまま、長辺が[maxSide]以下になる縮小後の大きさを返す
  ///
  /// [width]と[height]は、**向きを直した後**の縦横を渡すこと。縦に撮った写真は、画像の
  /// データが横長のまま向きの情報だけで縦に見えることがあり、向きを直す前の値だと、
  /// 縦横が逆の大きさで縮小を頼んでしまう。縮小は、頼んだ大きさ「以上」になる向きに
  /// 行われるので、縦長の写真が、長辺1024を大きく超える(例: 1024x1820)ままになる。
  /// 大きさが分からないとき(0以下)は、正方形で頼む。拡大はしない
  @visibleForTesting
  static ThumbnailSize fitSize(int width, int height, int maxSide) {
    final longSide = max(width, height);
    if (longSide <= 0) {
      return ThumbnailSize.square(maxSide);
    }

    final scale = min(1.0, maxSide / longSide);
    return ThumbnailSize(
      max(1, (width * scale).round()),
      max(1, (height * scale).round()),
    );
  }
}
