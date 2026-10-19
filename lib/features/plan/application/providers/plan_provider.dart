import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/app_info/client_id.dart';
import '../../../ai/application/providers/ai_provider.dart';
import '../../../points/application/providers/device_link_provider.dart';
import '../../data/aws_usage_repository_impl.dart';
import '../../data/file_plan_repository.dart';
import '../../domain/entities/plan_type.dart';
import '../../domain/entities/usage_info.dart';
import '../../domain/repositories/plan_repository.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../../domain/repositories/usage_repository.dart';
import '../../domain/entities/plan_product.dart';

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

final usageRepositoryProvider = Provider<UsageRepository>((ref) {
  return AwsUsageRepositoryImpl(
    ref.watch(apiBaseUrlProvider),
    clientId: ClientId.get,
    deviceToken: ref.read(deviceLinkProvider.notifier).token,
    onInvalidDeviceToken: ref.read(deviceLinkProvider.notifier).unlink,
  );
});

/// 今月のAIの使用量(サーバーから取得するまでは、分からないのでnull)
final usageProvider =
    NotifierProvider<UsageNotifier, UsageInfo?>(UsageNotifier.new);

class UsageNotifier extends Notifier<UsageInfo?> {
  @override
  UsageInfo? build() => null;

  /// サーバーから使用量を取得する(取得できなかった場合は、前の値のままにする)
  Future<void> refresh() async {
    final usage = await ref
        .read(usageRepositoryProvider)
        .fetch(plan: ref.read(planTypeProvider));
    if (usage != null) update(usage);
  }

  /// サーバーから受け取った使用量を反映する
  /// サーバーがプランを返した場合は、アプリのプランもそれに合わせる
  void update(UsageInfo usage) {
    state = usage;

    final plan = usage.plan;
    if (plan != null && plan != ref.read(planTypeProvider)) {
      ref.read(planTypeProvider.notifier).setPlan(plan);
    }
  }
}

// アプリ内課金。Google Play・App Storeの実装を入れるときは、ここで差し替える
final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  return UnavailablePurchaseRepository();
});

/// 販売している有料プラン
final planProductsProvider = FutureProvider<List<PlanProduct>>((ref) {
  return ref.watch(purchaseRepositoryProvider).loadProducts();
});
