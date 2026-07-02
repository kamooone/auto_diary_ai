import 'package:photo_manager/photo_manager.dart';

class GetTodayPhotosUseCase {
  Future<List<AssetEntity>> execute(DateTime targetDate) async {
    final permission = await PhotoManager.requestPermissionExtend();

    if (!permission.hasAccess) {
      throw Exception("写真権限なし");
    }

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );

    if (albums.isEmpty) return [];

    final album = albums.first;

    final startOfDay =
    DateTime(targetDate.year, targetDate.month, targetDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final List<AssetEntity> result = [];
    int page = 0;
    const pageSize = 50;

    while (true) {
      final photos = await album.getAssetListPaged(
        page: page,
        size: pageSize,
      );

      if (photos.isEmpty) break;

      bool stop = false;

      for (final photo in photos) {
        if (!photo.createDateTime.isBefore(startOfDay) &&
            photo.createDateTime.isBefore(endOfDay)) {
          result.add(photo);
        } else if (photo.createDateTime.isBefore(startOfDay)) {
          stop = true;
          break;
        }
      }

      if (stop) break;
      page++;
    }

    return result;
  }
}