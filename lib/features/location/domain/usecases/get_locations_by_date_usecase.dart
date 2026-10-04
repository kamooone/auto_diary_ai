import '../entities/location.dart';
import '../repositories/location_repository.dart';

class GetLocationsByDateUseCase {

  final LocationRepository repository;

  GetLocationsByDateUseCase(
      this.repository,
      );

  Future<List<Location>> execute(
      DateTime date,
      ) {
    return repository.getLocationsByDate(
      date,
    );
  }
}