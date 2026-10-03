import 'dart:typed_data';

class AiImage {
  final Uint8List bytes;
  final String contentType;

  const AiImage({
    required this.bytes,
    required this.contentType,
  });
}

class AiMessageRequest {
  final String message;
  final List<AiImage> images;

  const AiMessageRequest({
    required this.message,
    this.images = const [],
  });
}
