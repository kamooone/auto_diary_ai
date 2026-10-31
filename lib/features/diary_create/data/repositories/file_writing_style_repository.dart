import 'dart:convert';
import 'dart:io';
import '../../domain/repositories/writing_style_repository.dart';
import '../../domain/services/writing_style.dart';

/// 文体の希望を、端末内のファイルに保存する
class FileWritingStyleRepository implements WritingStyleRepository {
  // アプリのデータ用フォルダは非同期で決まるため、読み書きのときに解決する
  final Future<File> Function() _resolveFile;

  FileWritingStyleRepository(this._resolveFile);

  @override
  Future<String> load() async {
    try {
      final file = await _resolveFile();
      if (!await file.exists()) return WritingStyle.defaultText;

      final data = jsonDecode(await file.readAsString());
      final text = data is Map ? data['style'] : null;

      // 空にして保存した場合は、空のまま(希望なし)として扱う
      return text is String ? text : WritingStyle.defaultText;
    } catch (_) {
      return WritingStyle.defaultText;
    }
  }

  @override
  Future<void> save(String text) async {
    final file = await _resolveFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode({'style': text}));
  }

  @override
  Future<void> reset() async {
    final file = await _resolveFile();
    if (await file.exists()) await file.delete();
  }
}
