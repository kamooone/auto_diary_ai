import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../../data/repositories/aws_ai_repository_impl.dart';
import '../../domain/repositories/ai_repository.dart';

// Repository
final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return AwsAiRepositoryImpl(
    dotenv.env["API_BASE_URL"]!,
  );
});

// UseCase
final sendMessageUseCaseProvider = Provider((ref) {
  return SendMessageUseCase(ref.read(aiRepositoryProvider));
});
