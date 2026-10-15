import '../entities/ai_message_request.dart';
import '../entities/ai_reply.dart';

abstract class AiRepository {
  /// 使用量の上限に達している場合は、UsageLimitExceededExceptionを投げる
  Future<AiReply> sendMessage(
      AiMessageRequest request,
      );
}
