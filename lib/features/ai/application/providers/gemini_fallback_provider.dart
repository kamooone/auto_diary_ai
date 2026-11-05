import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Geminiが混んでいて失敗したとき、1つ性能が低いモデルで書き直すか(初めはオフ)
///
/// 性能が低いモデルは、文章の質が下がることがあるので、ユーザーが選んだときだけ使う
final geminiFallbackProvider =
    NotifierProvider<GeminiFallbackNotifier, bool>(GeminiFallbackNotifier.new);

class GeminiFallbackNotifier extends Notifier<bool> {
  var _isDisposed = false;

  // 読み込みが終わる前に切り替えた場合は、遅れて届いた読み込み結果で上書きしない
  var _isChanged = false;

  @override
  bool build() {
    ref.onDispose(() => _isDisposed = true);
    _load();
    return false;
  }

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/gemini_fallback.json');
  }

  Future<void> _load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return;

      final data = jsonDecode(await file.readAsString());
      final enabled = data is Map ? data['enabled'] : null;

      if (enabled is bool && !_isDisposed && !_isChanged) state = enabled;
    } catch (_) {
      // 読めない場合は、オフのままにする
    }
  }

  Future<void> set(bool enabled) async {
    _isChanged = true;
    state = enabled;

    try {
      final file = await _file();
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode({'enabled': enabled}));
    } catch (_) {
      // 保存できなくても、このあいだは選んだ内容を使う
    }
  }
}
