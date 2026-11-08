import 'dart:typed_data';
import '../entities/photo.dart';
import '../repositories/photo_repository.dart';

class GetPhotoThumbnailUseCase {
  final PhotoRepository repository;

  GetPhotoThumbnailUseCase(this.repository);

  Future<Uint8List?> execute(Photo photo) {
    return repository.getThumbnail(photo);
  }
}
