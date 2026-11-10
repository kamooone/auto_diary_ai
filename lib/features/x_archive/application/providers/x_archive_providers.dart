import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/isar_provider.dart';
import '../../data/repositories/x_archive_repository_impl.dart';
import '../../domain/repositories/x_archive_repository.dart';

final xArchiveRepositoryProvider = Provider<XArchiveRepository>((ref) {
  return XArchiveRepositoryImpl(ref.watch(isarProvider));
});
