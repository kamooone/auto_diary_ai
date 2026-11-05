/// 画像アップロード(ai-upload-url)の失敗
class AiUploadException implements Exception {
  final String message;

  AiUploadException(this.message);

  @override
  String toString() => 'AiUploadException: $message';
}

/// AI(Gemini・OpenAI)側が、混雑などで応答できなかった(サーバーが502を返した)。
/// このとき、トークンは使われない。少し時間をおくと、直ることが多い
class AiBusyException implements Exception {
  /// 原因を調べるための、サーバーが返した内容(長いものは切ってある)
  final String details;

  AiBusyException([this.details = '']);

  @override
  String toString() => 'AiBusyException: $details';
}

/// 日記生成(ai-chat)の失敗
class AiChatException implements Exception {
  final String message;

  AiChatException(this.message);

  @override
  String toString() => 'AiChatException: $message';
}
