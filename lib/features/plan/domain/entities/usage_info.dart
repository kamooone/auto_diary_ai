import 'plan_type.dart';

/// 今月のAIの使用量(サーバーが集計したトークン数)
class UsageInfo {
  /// サーバーが判定した現在のプラン(分からない場合はnull)
  final PlanType? plan;

  /// 今月に使ったトークン数
  final int usedTokens;

  /// 今月に使えるトークン数の上限
  final int limitTokens;

  /// 使用量がリセットされる日時(分からない場合はnull)
  final DateTime? resetsAt;

  const UsageInfo({
    this.plan,
    required this.usedTokens,
    required this.limitTokens,
    this.resetsAt,
  });

  /// 残りのトークン数(0未満にはしない)
  int get remainingTokens =>
      (limitTokens - usedTokens).clamp(0, limitTokens).toInt();

  /// 上限に対する使用量の割合(0〜1)
  double get ratio =>
      limitTokens <= 0 ? 1 : (usedTokens / limitTokens).clamp(0.0, 1.0);

  /// 上限に達していて、リセットされるまで使えないか
  bool get isExceeded => limitTokens > 0 && usedTokens >= limitTokens;

  /// サーバーの応答から読み取る(形式が想定と違う場合はnull)
  ///
  /// 例: {"plan": "free", "usage": {"usedTokens": 1200, "limitTokens": 50000,
  ///       "resetsAt": "2026-11-01T00:00:00+09:00"}}
  static UsageInfo? fromJson(Object? json) {
    if (json is! Map) return null;

    final usage = json['usage'];
    if (usage is! Map) return null;

    final used = usage['usedTokens'];
    final limit = usage['limitTokens'];
    if (used is! num || limit is! num) return null;

    final resetsAt = usage['resetsAt'];
    final plan = json['plan'];

    return UsageInfo(
      plan: PlanType.values.where((e) => e.name == plan).firstOrNull,
      usedTokens: used.toInt(),
      limitTokens: limit.toInt(),
      resetsAt: resetsAt is String ? DateTime.tryParse(resetsAt) : null,
    );
  }
}
