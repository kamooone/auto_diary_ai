import '../../../plan/domain/entities/usage_info.dart';

/// AIからの返答と、この返答までの今月の使用量
class AiReply {
  final String answer;

  /// 今月の使用量(サーバーが返さない場合はnull)
  final UsageInfo? usage;

  /// 実際に答えたモデルの名前(サーバーが返さない場合はnull)
  final String? modelName;

  const AiReply({required this.answer, this.usage, this.modelName});
}
