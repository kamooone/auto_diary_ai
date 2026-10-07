import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/isar_provider.dart';
import '../../data/datasources/gps_location_datasource.dart';
import '../../data/datasources/isar_location_datasource.dart';
import '../../data/datasources/isar_place_candidate_cache.dart';
import '../../data/repositories/activity_repository_impl.dart';
import '../../data/repositories/location_repository_impl.dart';
import '../../data/repositories/osm_place_search_repository_impl.dart';
import '../../data/repositories/place_name_repository_impl.dart';
import '../../data/repositories/timeline_edit_repository_impl.dart';
import '../../data/repositories/timeline_snapshot_repository_impl.dart';
import '../../domain/repositories/activity_repository.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/repositories/place_name_repository.dart';
import '../../domain/repositories/place_search_repository.dart';
import '../../domain/repositories/timeline_edit_repository.dart';
import '../../domain/repositories/timeline_snapshot_repository.dart';
import '../../domain/usecases/get_latest_location_usecase.dart';
import '../../domain/usecases/get_locations_by_date_usecase.dart';
import '../../domain/usecases/get_place_candidates_usecase.dart';
import '../../domain/usecases/get_timeline_by_date_usecase.dart';
import '../../domain/usecases/start_location_tracking_usecase.dart';
import '../../domain/usecases/update_move_transport_usecase.dart';
import '../../domain/usecases/update_stay_place_name_usecase.dart';

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

  return PlaceNameRepositoryImpl(
    ref.watch(isarProvider),
  );

});

// 施設の情報源。将来、別の情報源に切り替える場合はここで実装を差し替える
final placeSearchRepositoryProvider =
Provider<PlaceSearchRepository>((ref) {

  return OsmPlaceSearchRepositoryImpl(
    cache: IsarPlaceCandidateCache(
      ref.watch(isarProvider),
    ),
  );

});

final activityRepositoryProvider =
Provider<ActivityRepository>((ref) {

  return ActivityRepositoryImpl(
    ref.watch(isarProvider),
  );

});

final timelineSnapshotRepositoryProvider =
Provider<TimelineSnapshotRepository>((ref) {

  return TimelineSnapshotRepositoryImpl(
    ref.watch(isarProvider),
  );

});

final timelineEditRepositoryProvider =
Provider<TimelineEditRepository>((ref) {

  return TimelineEditRepositoryImpl(
    ref.watch(isarProvider),
  );

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
    repository: ref.watch(locationRepositoryProvider),
    placeNameRepository: ref.watch(placeNameRepositoryProvider),
    timelineEditRepository: ref.watch(timelineEditRepositoryProvider),
    placeSearchRepository: ref.watch(placeSearchRepositoryProvider),
    activityRepository: ref.watch(activityRepositoryProvider),
    timelineSnapshotRepository: ref.watch(timelineSnapshotRepositoryProvider),
  );

});

final updateStayPlaceNameUseCaseProvider =
Provider((ref) {

  return UpdateStayPlaceNameUseCase(
    ref.watch(timelineEditRepositoryProvider),
  );

});

final updateMoveTransportUseCaseProvider =
Provider((ref) {

  return UpdateMoveTransportUseCase(
    ref.watch(timelineEditRepositoryProvider),
  );

});

final getPlaceCandidatesUseCaseProvider =
Provider((ref) {

  return GetPlaceCandidatesUseCase(
    ref.watch(placeSearchRepositoryProvider),
  );

});