import 'dart:convert';
import 'dart:io';
import '../../domain/entities/diary_style.dart';
import '../../domain/repositories/diary_style_repository.dart';

/// ふつうのAI日記の書き方の選択を、端末内のファイルに保存する
class FileDiaryStyleRepository implements DiaryStyleRepository {
  // アプリのデータ用フォルダは非同期で決まるため、読み書きのときに解決する
  final Future<File> Function() _resolveFile;

  FileDiaryStyleRepository(this._resolveFile);

  @override
  Future<DiaryStyle> load() async {
    try {
      final file = await _resolveFile();
      if (!await file.exists()) return DiaryStyle.diary;

      final data = jsonDecode(await file.readAsString());
      final style = DiaryStyle.fromName(data is Map ? data['style'] : null);

      // 書いた指示は残さないので、「自分で指定」は日記に戻す
      return style == DiaryStyle.custom ? DiaryStyle.diary : style;
    } catch (_) {
      return DiaryStyle.diary;
    }
  }

  @override
  Future<void> save(DiaryStyle style) async {
    final file = await _resolveFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode({'style': style.name}));
  }
}
