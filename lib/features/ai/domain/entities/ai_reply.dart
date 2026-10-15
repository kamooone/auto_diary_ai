import '../../../plan/domain/entities/usage_info.dart';

/// AIからの返答と、この返答までの今月の使用量
class AiReply {
  final String answer;

  /// 今月の使用量(サーバーが返さない場合はnull)
  final UsageInfo? usage;

  const AiReply({required this.answer, this.usage});
}
