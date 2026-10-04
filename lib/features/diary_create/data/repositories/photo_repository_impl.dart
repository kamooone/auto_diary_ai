import 'dart:math';
import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';
import '../../domain/entities/photo.dart';
import '../../domain/entities/photo_location.dart';
import '../../domain/exceptions/photo_exception.dart';
import '../../domain/repositories/photo_repository.dart';

class PhotoRepositoryImpl implements PhotoRepository {
  static const _thumbnailSide = 200;

  // 取得済みのAssetEntityをidから引けるように保持する
  final _assets = <String, AssetEntity>{};

  @override
  Future<List<Photo>> getPhotos({
    required int page,
    required int size,
  }) async {
    // 撮影場所も読み取れるよう、Androidでは位置情報付きで許可を求める
    final permission = await PhotoManager.requestPermissionExtend(
      requestOption: const PermissionRequestOption(
        androidPermission: AndroidPermission(
          type: RequestType.common,
          mediaLocation: true,
        ),
      ),
    );

    if (!permission.hasAccess) {
      throw PhotoPermissionException();
    }

    final filter = FilterOptionGroup(
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
  Future<PhotoLocation?> getLocation(Photo photo) async {
    final asset = await _findAsset(photo.id);
    if (asset == null) return null;

    try {
      final latLng = await asset.latlngAsync();

      // 位置情報が付いていない写真は(0, 0)が返る
      if (latLng == null || (latLng.latitude == 0 && latLng.longitude == 0)) {
        return null;
      }

      return PhotoLocation(
        latitude: latLng.latitude,
        longitude: latLng.longitude,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Uint8List?> getJpeg(
    Photo photo, {
    required int maxSide,
    required int quality,
  }) async {
    final asset = await _findAsset(photo.id);
    if (asset == null) return null;

    return asset.thumbnailDataWithSize(
      _fitSize(asset, maxSide),
      format: ThumbnailFormat.jpeg,
      quality: quality,
    );
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
