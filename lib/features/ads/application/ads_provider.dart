import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/ad_gateway.dart';
import '../domain/ad_policy.dart';

/// 広告の表示(AdMobなど)。起動時に、実際の広告に差し替える
final adGatewayProvider = Provider<AdGateway>((ref) => NoAdGateway());

/// 広告を表示するか
/// いまはすべてのプランに表示する。プランで変える場合は、ここで判定する
final adsEnabledProvider = Provider<bool>((ref) => true);

final adPolicyProvider = Provider<AdPolicy>((ref) {
  return AdPolicy(
    gateway: ref.watch(adGatewayProvider),
    enabled: ref.watch(adsEnabledProvider),
  );
});
