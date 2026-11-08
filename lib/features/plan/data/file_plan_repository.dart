import 'dart:convert';
import 'dart:io';
import '../domain/entities/plan_type.dart';
import '../domain/repositories/plan_repository.dart';

/// 現在のプランを、端末内のファイルに保存する
class FilePlanRepository implements PlanRepository {
  // アプリのデータ用フォルダは非同期で決まるため、読み書きのときに解決する
  final Future<File> Function() _resolveFile;

  FilePlanRepository(this._resolveFile);

  @override
  Future<PlanType> load() async {
    try {
      final file = await _resolveFile();
      if (!await file.exists()) return PlanType.free;

      final data = jsonDecode(await file.readAsString());
      final name = data is Map ? data['plan'] : null;

      return PlanType.values.where((e) => e.name == name).firstOrNull ??
          PlanType.free;
    } catch (_) {
      // 読めない場合は、有料にしてしまわないよう無料として扱う
      return PlanType.free;
    }
  }

  @override
  Future<void> save(PlanType plan) async {
    final file = await _resolveFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode({'plan': plan.name}));
  }
}
