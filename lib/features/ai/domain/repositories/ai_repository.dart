import '../entities/ai_message_request.dart';

abstract class AiRepository {
  Future<String> sendMessage(
      AiMessageRequest request,
      );
}