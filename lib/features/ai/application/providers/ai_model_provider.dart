import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/ai_model.dart';

/// ユーザーが選んだAIの種類(選んでいなければ Gemini)
final aiModelProvider =
    NotifierProvider<AiModelNotifier, AiModel>(AiModelNotifier.new);

class AiModelNotifier extends Notifier<AiModel> {
  var _isDisposed = false;

  // 読み込みが終わる前に選んだ場合は、遅れて届いた読み込み結果で上書きしない
  var _isChanged = false;

  @override
  AiModel build() {
    ref.onDispose(() => _isDisposed = true);
    _load();
    return AiModel.gemini;
  }

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/ai_model.json');
  }

  Future<void> _load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return;

      final data = jsonDecode(await file.readAsString());
      final name = data is Map ? data['model'] : null;
      final model = AiModel.values.where((e) => e.name == name).firstOrNull;

      if (model != null && !_isDisposed && !_isChanged) state = model;
    } catch (_) {
      // 読めない場合は、Gemini のままにする
    }
  }

  Future<void> select(AiModel model) async {
    _isChanged = true;
    state = model;

    try {
      final file = await _file();
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode({'model': model.name}));
    } catch (_) {
      // 保存できなくても、このあいだは選んだ内容を使う
    }
  }
}
