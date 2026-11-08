import 'dart:typed_data';
import '../../../plan/domain/entities/plan_type.dart';

class AiImage {
  final Uint8List bytes;
  final String contentType;

  const AiImage({
    required this.bytes,
    required this.contentType,
  });
}

class AiMessageRequest {
  /// AIに渡す文章の全文(旧。サーバーが ALLOW_RAW_MESSAGE を許している間だけ使える)
  /// 日記まわりは、[prompt]を使う
  final String message;

  /// AIに渡す文章の材料と設定(サーバーが、指示と合わせて組み立てる)
  /// 形は、PromptSpec(日記・日記を1つにする・相談)が作る
  final Map<String, Object?>? prompt;
  final List<AiImage> images;

  /// 利用しているプラン(サーバーが、使うAIを切り替えるのに使う)
  final PlanType plan;

  const AiMessageRequest({
    this.message = '',
    this.prompt,
    this.images = const [],
    this.plan = PlanType.free,
  });
}
