import '../entities/location.dart';
import '../repositories/location_repository.dart';

class GetLatestLocationUseCase {

  final LocationRepository repository;

  GetLatestLocationUseCase(
      this.repository,
      );

  Future<Location?> execute() {
    return repository.getLatestLocation();
  }
}