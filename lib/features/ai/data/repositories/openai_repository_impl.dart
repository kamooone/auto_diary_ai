import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/repositories/ai_repository.dart';

class OpenAiRepositoryImpl implements AiRepository {
  final String apiKey;

  OpenAiRepositoryImpl(this.apiKey);

  @override
  Future<String> sendMessage(String message) async {
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        "model": "gpt-4o-mini",
        "messages": [
          {
            "role": "user",
            "content": message,
          }
        ]
      }),
    );

    final data = jsonDecode(response.body);

    print(response.statusCode);
    print(response.body);

    return data['choices'][0]['message']['content'];
  }
}