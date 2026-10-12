import 'package:isar/isar.dart';
import '../../domain/entities/registered_place.dart';
import '../../domain/repositories/registered_place_repository.dart';
import '../models/registered_place_log.dart';

class RegisteredPlaceRepositoryImpl implements RegisteredPlaceRepository {
  final Isar isar;

  RegisteredPlaceRepositoryImpl(this.isar);

  @override
  Future<List<RegisteredPlace>> getAll() async {
    final logs = await isar.registeredPlaceLogs.where().findAll();

    return [
      for (final log in logs)
        RegisteredPlace(
          id: log.id,
          latitude: log.latitude,
          longitude: log.longitude,
          name: log.name,
        ),
    ];
  }

  @override
  Future<void> save(RegisteredPlace place) async {
    final log = RegisteredPlaceLog()
      ..latitude = place.latitude
      ..longitude = place.longitude
      ..name = place.name;

    final id = place.id;
    if (id != null) {
      log.id = id;
    }

    await isar.writeTxn(() async {
      await isar.registeredPlaceLogs.put(log);
    });
  }

  @override
  Future<void> delete(int id) async {
    await isar.writeTxn(() async {
      await isar.registeredPlaceLogs.delete(id);
    });
  }
}
