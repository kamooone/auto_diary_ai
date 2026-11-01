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
  Future<SummaryStyleSetting> load() async {
    try {
      final file = await _resolveFile();
      if (!await file.exists()) return const SummaryStyleSetting();

      final data = jsonDecode(await file.readAsString());
      if (data is! Map) return const SummaryStyleSetting();

      final custom = data['custom'];

      return SummaryStyleSetting(
        style: SummaryStyle.fromName(data['style']),
        customInstruction: custom is String ? custom : '',
      );
    } catch (_) {
      return const SummaryStyleSetting();
    }
  }

  @override
  Future<void> save(SummaryStyleSetting setting) async {
    final file = await _resolveFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode({
        'style': setting.style.name,
        'custom': setting.customInstruction,
      }),
    );
  }
}
