import '../../features/diary/data/models/diary_log.dart';
import '../../features/location/data/models/activity_log.dart';
import '../app_info/app_info.dart';
import '../../features/location/data/models/location_log.dart';
import '../../features/location/data/models/place_name_cache.dart';
import '../../features/location/data/models/place_search_cache.dart';
import '../../features/location/data/models/timeline_edit_log.dart';
import '../../features/location/data/models/timeline_snapshot.dart';
import '../../features/share/data/models/shared_post_model.dart';

final isarSchemas = [
  LocationLogSchema,
  TimelineEditLogSchema,
  PlaceSearchCacheSchema,
  ActivityLogSchema,
  AppInfoSchema,
  DiaryLogSchema,
  PlaceNameCacheSchema,
  TimelineSnapshotSchema,
  SharedPostModelSchema,
];