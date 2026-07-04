import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../domain/entities/ai_message_request.dart';
import '../../domain/repositories/ai_repository.dart';

class OpenAiRepositoryImpl implements AiRepository {
  final String apiKey;

  OpenAiRepositoryImpl(this.apiKey);

  @override
  Future<String> sendMessage(
      AiMessageRequest request,
      ) async {

    final List<Map<String, dynamic>> content = [
      {
        "type": "text",
        "text": request.message,
      },
    ];

    for (final image in request.images) {
      final bytes = await image.readAsBytes();

      final base64 = base64Encode(bytes);

      content.add({
        "type": "image_url",
        "image_url": {
          "url": "data:image/jpeg;base64,$base64",
        },
      });
    }

    final response = await http.post(
      Uri.parse("https://api.openai.com/v1/chat/completions"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $apiKey",
      },
      body: jsonEncode({
        "model": "gpt-4o-mini",
        "messages": [
          {
            "role": "user",
            "content": content,
          }
        ]
      }),
    );

    print(response.statusCode);
    print(response.body);

    final data = jsonDecode(response.body);

    return data["choices"][0]["message"]["content"];
  }
}