import '../entities/location.dart';
import '../repositories/location_repository.dart';

class GetLocationsUseCase {

  final LocationRepository repository;

  GetLocationsUseCase(
      this.repository,
      );

  Future<List<Location>> execute() {
    return repository.getLocations();
  }
}