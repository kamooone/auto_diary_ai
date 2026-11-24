import 'package:auto_diary_ai/features/tutorial/data/tutorial_seen_store.dart';

/// すべてのチュートリアルを、見たことにする(チュートリアルが出ない状態で、画面を確かめるとき)
class AllSeenTutorialStore implements TutorialSeenStore {
  @override
  Future<bool> hasSeen(String id) async => true;

  @override
  Future<void> markSeen(String id) async {}

  @override
  Future<void> clearAll() async {}
}

/// 見たチュートリアルを、メモリに覚える(チュートリアルが、出るか・覚えられるかを確かめるとき)
class MemoryTutorialStore implements TutorialSeenStore {
  final seen = <String>{};

  @override
  Future<bool> hasSeen(String id) async => seen.contains(id);

  @override
  Future<void> markSeen(String id) async => seen.add(id);

  @override
  Future<void> clearAll() async => seen.clear();
}
