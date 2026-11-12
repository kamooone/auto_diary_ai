import 'dart:io';

import 'package:auto_diary_ai/features/tutorial/data/tutorial_seen_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  late File file;
  late FileTutorialSeenStore store;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('tutorial_seen');
    file = File('${dir.path}/tutorial_seen.json');
    store = FileTutorialSeenStore(() async => file);
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('最初は、どれも見ていない', () async {
    expect(await store.hasSeen('home'), isFalse);
  });

  test('見た印を付けると、その画面だけ見たことになり、作り直しても残る', () async {
    await store.markSeen('home');

    expect(await store.hasSeen('home'), isTrue);
    expect(await store.hasSeen('calendar'), isFalse);

    final reopened = FileTutorialSeenStore(() async => file);
    expect(await reopened.hasSeen('home'), isTrue);
  });

  test('ファイルが壊れていても、見ていないことにして動く', () async {
    file.writeAsStringSync('{{{');

    expect(await store.hasSeen('home'), isFalse);
    await store.markSeen('home');
    expect(await store.hasSeen('home'), isTrue);
  });
}
