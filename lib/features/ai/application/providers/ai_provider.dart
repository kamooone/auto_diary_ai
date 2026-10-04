import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/aws_ai_repository_impl.dart';
import '../../domain/repositories/ai_repository.dart';

// APIのベースURL(.envのAPI_BASE_URL)
final apiBaseUrlProvider = Provider<String>((ref) {
  final baseUrl = dotenv.env["API_BASE_URL"];

  if (baseUrl == null || baseUrl.isEmpty) {
    throw StateError("API_BASE_URLが.envに設定されていません");
  }
  return baseUrl;
});

// Repository
final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return AwsAiRepositoryImpl(
    ref.watch(apiBaseUrlProvider),
  );
});
