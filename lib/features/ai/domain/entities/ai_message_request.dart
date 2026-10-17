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
  final String message;
  final List<AiImage> images;

  /// 利用しているプラン(サーバーが、使うAIを切り替えるのに使う)
  final PlanType plan;

  const AiMessageRequest({
    required this.message,
    this.images = const [],
    this.plan = PlanType.free,
  });
}
