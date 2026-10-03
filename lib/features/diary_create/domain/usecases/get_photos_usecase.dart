import 'package:photo_manager/photo_manager.dart';

class GetPhotosUseCase {
  // 端末内の写真を新しい順にページ単位で取得する
  Future<List<AssetEntity>> execute({
    required int page,
    required int size,
  }) async {
    final permission = await PhotoManager.requestPermissionExtend();

    if (!permission.hasAccess) {
      throw Exception("写真権限なし");
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

    return albums.first.getAssetListPaged(
      page: page,
      size: size,
    );
  }
}
