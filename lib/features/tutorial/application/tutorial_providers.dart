import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../data/tutorial_seen_store.dart';

final tutorialSeenStoreProvider = Provider<TutorialSeenStore>((ref) {
  return FileTutorialSeenStore(() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/tutorial_seen.json');
  });
});
