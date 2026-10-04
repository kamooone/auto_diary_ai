import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/isar_provider.dart';
import '../../data/datasources/gps_location_datasource.dart';
import '../../data/datasources/isar_location_datasource.dart';
import '../../data/repositories/location_repository_impl.dart';
import '../../data/repositories/place_name_repository_impl.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/repositories/place_name_repository.dart';
import '../../domain/usecases/get_latest_location_usecase.dart';
import '../../domain/usecases/get_locations_by_date_usecase.dart';
import '../../domain/usecases/get_timeline_by_date_usecase.dart';
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
    ref.watch(isarProvider),
  );

});

///--------------------------------------
/// Repository
///--------------------------------------

final locationRepositoryProvider =
Provider<LocationRepository>((ref) {

  return LocationRepositoryImpl(
    gps: ref.watch(gpsLocationDataSourceProvider),
    local: ref.watch(isarLocationDataSourceProvider),
  );

});

final placeNameRepositoryProvider =
Provider<PlaceNameRepository>((ref) {

  return PlaceNameRepositoryImpl();

});

///--------------------------------------
/// UseCases
///--------------------------------------

final startLocationTrackingUseCaseProvider =
Provider((ref) {

  return StartLocationTrackingUseCase(
    ref.watch(locationRepositoryProvider),
  );

});

final getLocationsByDateUseCaseProvider =
Provider((ref) {

  return GetLocationsByDateUseCase(
    ref.watch(locationRepositoryProvider),
  );

});

final getLatestLocationUseCaseProvider =
Provider((ref) {

  return GetLatestLocationUseCase(
    ref.watch(locationRepositoryProvider),
  );

});

final getTimelineByDateUseCaseProvider =
Provider((ref) {

  return GetTimelineByDateUseCase(
    ref.watch(locationRepositoryProvider),
    ref.watch(placeNameRepositoryProvider),
  );

});