import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
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
      );
    }).toList();
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
              _fitSize(asset, side),
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

  // 縦横比を保ったまま、長辺がmaxSide以下になるサイズを返す
  ThumbnailSize _fitSize(AssetEntity asset, int maxSide) {
    final longSide = max(asset.width, asset.height);
    if (longSide <= 0) {
      return ThumbnailSize.square(maxSide);
    }

    final scale = min(1.0, maxSide / longSide);
    return ThumbnailSize(
      max(1, (asset.width * scale).round()),
      max(1, (asset.height * scale).round()),
    );
  }
}
