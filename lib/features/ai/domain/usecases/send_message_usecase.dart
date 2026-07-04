import '../entities/ai_message_request.dart';
import '../repositories/ai_repository.dart';

class SendMessageUseCase {
  final AiRepository repository;

  SendMessageUseCase(this.repository);

  Future<String> execute(AiMessageRequest request,) {
    return repository.sendMessage(request);
  }
}