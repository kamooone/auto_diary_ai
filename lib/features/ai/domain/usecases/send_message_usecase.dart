import '../repositories/ai_repository.dart';

class SendMessageUseCase {
  final AiRepository repository;

  SendMessageUseCase(this.repository);

  Future<String> execute(String message) {
    return repository.sendMessage(message);
  }
}