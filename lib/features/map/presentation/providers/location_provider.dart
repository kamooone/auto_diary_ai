import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_diary_ai/core/database/isar_provider.dart';
import '../../data/repositories/location_repository.dart';
import '../../data/services/location_service.dart';

final locationRepositoryProvider = Provider<LocationRepository>((ref) {

  final isar = ref.watch(isarProvider);

  return LocationRepository(isar);
});

final locationServiceProvider = Provider<LocationService>((ref) {

  final repo = ref.watch(locationRepositoryProvider);

  return LocationService(repo);
});