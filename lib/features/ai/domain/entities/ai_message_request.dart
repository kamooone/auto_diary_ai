import 'dart:io';

class AiMessageRequest {
  final String message;
  final List<File> images;

  const AiMessageRequest({
    required this.message,
    this.images = const [],
  });
}