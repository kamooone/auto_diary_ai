import 'dart:convert';
import 'dart:io';
import '../../domain/entities/summary_style.dart';
import '../../domain/repositories/summary_style_repository.dart';

/// 書き方の選択を、端末内のファイルに保存する
class FileSummaryStyleRepository implements SummaryStyleRepository {
  // アプリのデータ用フォルダは非同期で決まるため、読み書きのときに解決する
  final Future<File> Function() _resolveFile;

  FileSummaryStyleRepository(this._resolveFile);

  @override
  Future<SummaryStyle> load() async {
    try {
      final file = await _resolveFile();
      if (!await file.exists()) return SummaryStyle.reading;

      final data = jsonDecode(await file.readAsString());
      final style = SummaryStyle.fromName(data is Map ? data['style'] : null);

      // 書いた指示は残さないので、「自分で指定」は読み物に戻す
      return style == SummaryStyle.custom ? SummaryStyle.reading : style;
    } catch (_) {
      return SummaryStyle.reading;
    }
  }

  @override
  Future<void> save(SummaryStyle style) async {
    final file = await _resolveFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode({'style': style.name}));
  }
}
