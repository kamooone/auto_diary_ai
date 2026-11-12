import 'dart:convert';
import 'dart:io';

/// どのチュートリアルを見たかを、この端末に覚えておく
///
/// チュートリアルは、画面ごと(あとで、機能ごと)に[id]を付けて、見たものは二度と自動では出さない
abstract class TutorialSeenStore {
  Future<bool> hasSeen(String id);

  Future<void> markSeen(String id);
}

/// 見たチュートリアルの[id]の一覧を、端末内のJSONファイルに保存する
class FileTutorialSeenStore implements TutorialSeenStore {
  // アプリのデータ用フォルダは非同期で決まるため、読み書きのときに解決する
  FileTutorialSeenStore(this._resolveFile);

  final Future<File> Function() _resolveFile;

  @override
  Future<bool> hasSeen(String id) async => (await _load()).contains(id);

  @override
  Future<void> markSeen(String id) async {
    try {
      final seen = await _load();
      if (!seen.add(id)) return;

      final file = await _resolveFile();
      await file.writeAsString(jsonEncode(seen.toList()));
    } catch (_) {
      // 保存できなくても、アプリは使えるようにする(次の起動で、もう一度出るだけ)
    }
  }

  Future<Set<String>> _load() async {
    try {
      final file = await _resolveFile();
      if (!await file.exists()) return {};

      final data = jsonDecode(await file.readAsString());
      if (data is! List) return {};

      return data.whereType<String>().toSet();
    } catch (_) {
      return {};
    }
  }
}
