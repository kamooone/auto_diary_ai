import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';

/// この端末(アプリのインストール)を識別する匿名のID
///
/// サーバーが、使用量を端末ごとに集計するために使う。個人情報は含まない
class ClientId {
  ClientId._();

  static Future<String>? _cached;

  static Future<String> get() => _cached ??= _load();

  static Future<String> _load() async {
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/client_id.txt');

    try {
      if (await file.exists()) {
        final saved = (await file.readAsString()).trim();
        if (saved.isNotEmpty) return saved;
      }
    } catch (_) {
      // 読めない場合は、作り直す
    }

    final id = generate();
    await file.parent.create(recursive: true);
    await file.writeAsString(id);
    return id;
  }

  /// 推測されにくい32桁のID
  static String generate([Random? random]) {
    final r = random ?? Random.secure();
    return List.generate(
      16,
      (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}
