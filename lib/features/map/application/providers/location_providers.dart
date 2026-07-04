import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/isar_provider.dart';
import '../../data/datasources/gps_location_datasource.dart';
import '../../data/datasources/isar_location_datasource.dart';
import '../../data/repositories/location_repository_impl.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/usecases/get_latest_location_usecase.dart';
import '../../domain/usecases/get_locations_by_date_usecase.dart';
import '../../domain/usecases/get_locations_usecase.dart';
import '../../domain/usecases/start_location_tracking_usecase.dart';

///--------------------------------------
/// DataSources
///--------------------------------------

final gpsLocationDataSourceProvider =
Provider<GpsLocationDataSource>((ref) {

  return GpsLocationDataSource();

});

final isarLocationDataSourceProvider =
Provider<IsarLocationDataSource>((ref) {

  return IsarLocationDataSource(
    ref.read(isarProvider),
  );

});

///--------------------------------------
/// Repository
///--------------------------------------

final locationRepositoryProvider =
Provider<LocationRepository>((ref) {

  return LocationRepositoryImpl(
    gps: ref.read(gpsLocationDataSourceProvider),
    local: ref.read(isarLocationDataSourceProvider),
  );

});

///--------------------------------------
/// UseCases
///--------------------------------------

final startLocationTrackingUseCaseProvider =
Provider((ref) {

  return StartLocationTrackingUseCase(
    ref.read(locationRepositoryProvider),
  );

});

final getLocationsUseCaseProvider =
Provider((ref) {

  return GetLocationsUseCase(
    ref.read(locationRepositoryProvider),
  );

});

final getLocationsByDateUseCaseProvider =
Provider((ref) {

  return GetLocationsByDateUseCase(
    ref.read(locationRepositoryProvider),
  );

});

final getLatestLocationUseCaseProvider =
Provider((ref) {

  return GetLatestLocationUseCase(
    ref.read(locationRepositoryProvider),
  );

});