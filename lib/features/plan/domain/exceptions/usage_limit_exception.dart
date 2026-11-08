import '../entities/usage_info.dart';

/// 今月の使用量の上限に達していて、AIを使えない
class UsageLimitExceededException implements Exception {
  /// サーバーが返した使用量(返ってこなかった場合はnull)
  final UsageInfo? usage;

  UsageLimitExceededException([this.usage]);

  @override
  String toString() => 'UsageLimitExceededException: $usage';
}
