import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../../data/repositories/openai_repository_impl.dart';
import '../../domain/repositories/ai_repository.dart';

// Repository
final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return OpenAiRepositoryImpl(
    dotenv.env["OPENAI_API_KEY"]!,
  );
});

// UseCase
final sendMessageUseCaseProvider = Provider((ref) {
  return SendMessageUseCase(ref.read(aiRepositoryProvider));
});