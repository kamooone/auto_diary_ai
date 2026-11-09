import '../entities/photo.dart';
import '../repositories/photo_repository.dart';

class GetPhotosUseCase {
  final PhotoRepository repository;

  GetPhotosUseCase(this.repository);

  Future<List<Photo>> execute({
    required int page,
    required int size,
    DateTime? from,
    DateTime? to,
  }) {
    return repository.getPhotos(page: page, size: size, from: from, to: to);
  }

  /// 一番古い写真の撮影日時(写真がない場合はnull)
  Future<DateTime?> oldestDate() => repository.getOldestDate();
}
