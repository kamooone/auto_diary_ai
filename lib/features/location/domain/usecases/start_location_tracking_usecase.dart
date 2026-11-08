import '../entities/location.dart';
import '../repositories/location_repository.dart';

class StartLocationTrackingUseCase {

  final LocationRepository repository;

  StartLocationTrackingUseCase(
      this.repository);

  Stream<Location> execute() {

    return repository.startTracking();

  }
}