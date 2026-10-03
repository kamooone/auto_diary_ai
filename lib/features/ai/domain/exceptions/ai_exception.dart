/// 画像アップロード(ai-upload-url)の失敗
class AiUploadException implements Exception {
  final String message;

  AiUploadException(this.message);

  @override
  String toString() => 'AiUploadException: $message';
}

/// 日記生成(ai-chat)の失敗
class AiChatException implements Exception {
  final String message;

  AiChatException(this.message);

  @override
  String toString() => 'AiChatException: $message';
}
