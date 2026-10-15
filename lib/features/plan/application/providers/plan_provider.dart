import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/file_plan_repository.dart';
import '../../domain/entities/plan_type.dart';
import '../../domain/repositories/plan_repository.dart';

final planRepositoryProvider = Provider<PlanRepository>((ref) {
  return FilePlanRepository(() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/plan.json');
  });
});

/// 現在のプラン(読み込みが終わるまでは無料プラン)
final planTypeProvider =
    NotifierProvider<PlanNotifier, PlanType>(PlanNotifier.new);

class PlanNotifier extends Notifier<PlanType> {
  var _isDisposed = false;

  // 読み込みが終わる前に切り替えた場合は、遅れて届いた読み込み結果で上書きしない
  var _isChanged = false;

  @override
  PlanType build() {
    ref.onDispose(() => _isDisposed = true);
    _load();
    return PlanType.free;
  }

  Future<void> _load() async {
    final plan = await ref.read(planRepositoryProvider).load();
    if (!_isDisposed && !_isChanged) state = plan;
  }

  Future<void> setPlan(PlanType plan) async {
    _isChanged = true;
    state = plan;
    await ref.read(planRepositoryProvider).save(plan);
  }
}
