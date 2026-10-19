import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../plan/domain/entities/usage_info.dart';
import '../../../plan/domain/exceptions/usage_limit_exception.dart';
import '../../domain/entities/ai_message_request.dart';
import '../../domain/entities/ai_reply.dart';
import '../../domain/exceptions/ai_exception.dart';
import '../../domain/repositories/ai_repository.dart';

class AwsAiRepositoryImpl implements AiRepository {
  final String baseUrl;
  final http.Client _client;

  // 端末を識別する匿名のID(サーバーが使用量を端末ごとに集計する)
  final Future<String> Function()? _clientId;

  // Webのアカウントと紐づけたときの、端末用のトークン(紐づけていなければnull)
  final Future<String?> Function()? _deviceToken;

  // サーバーに端末用のトークンを断られた(解除された)ときに呼ぶ
  final Future<void> Function()? _onInvalidDeviceToken;

  AwsAiRepositoryImpl(
    this.baseUrl, {
    http.Client? client,
    Future<String> Function()? clientId,
    Future<String?> Function()? deviceToken,
    Future<void> Function()? onInvalidDeviceToken,
  })  : _client = client ?? http.Client(),
        _clientId = clientId,
        _deviceToken = deviceToken,
        _onInvalidDeviceToken = onInvalidDeviceToken;

  static const _uploadPath = '/ai/upload-url';
  static const _chatPath = '/ai/chat';

  // API Gateway(REST)の統合タイムアウトが29秒のため、少し余裕を持たせる
  static const _timeout = Duration(seconds: 35);

  // Lambda同期呼び出しのペイロード上限(6MB)に収まるよう、Base64後の合計サイズを制限する
  static const _maxUploadBodyBytes = 5 * 1024 * 1024;

  @override
  Future<AiReply> sendMessage(AiMessageRequest request) async {
    // 画像をまとめてS3へアップロードし、S3キーを受け取る
    final uploadedImages = request.images.isEmpty
        ? const <dynamic>[]
        : await _uploadImages(request);

    // messageとS3キーを送って日記を生成する
    final data = await _post(
      _chatPath,
      jsonEncode({
        'message': request.message,
        'images': uploadedImages,
        'plan': request.plan.name,
      }),
      onError: AiChatException.new,
    );

    final answer = data['answer'];
    if (answer is! String) {
      throw AiChatException('answer is missing in response');
    }

    return AiReply(answer: answer, usage: UsageInfo.fromJson(data));
  }

  Future<List<dynamic>> _uploadImages(AiMessageRequest request) async {
    final body = jsonEncode({
      'message': request.message,
      'images': [
        for (final image in request.images)
          {
            'data': base64Encode(image.bytes),
            'contentType': image.contentType,
          },
      ],
    });

    final bodyBytes = utf8.encode(body).length;
    if (bodyBytes > _maxUploadBodyBytes) {
      throw AiUploadException('Upload payload too large: $bodyBytes bytes');
    }

    final data = await _post(
      _uploadPath,
      body,
      onError: AiUploadException.new,
    );

    final images = data['images'];
    if (images is! List || images.length != request.images.length) {
      throw AiUploadException('images is missing in response');
    }
    return images;
  }

  Future<Map<String, dynamic>> _post(
    String path,
    String body, {
    required Exception Function(String message) onError,
  }) async {
    http.Response response;

    try {
      var token = await _deviceToken?.call();
      response = await _send(path, body, token);

      // 紐づけが解除されている。トークンを捨てて、紐づけなしで送り直す
      if (response.statusCode == 401 && token != null) {
        await _onInvalidDeviceToken?.call();
        token = null;
        response = await _send(path, body, token);
      }
    } on TimeoutException {
      throw onError('Request timed out: $path');
    } on http.ClientException catch (e) {
      throw onError('Request failed: $path (${e.message})');
    }

    // 今月の使用量の上限に達している(使用量が分かる場合は本文に入っている)
    if (response.statusCode == 429) {
      throw UsageLimitExceededException(_usageOf(response));
    }

    if (response.statusCode != 200) {
      throw onError('Request failed: $path (${response.statusCode})');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is! Map<String, dynamic>) {
      throw onError('Unexpected response: $path');
    }
    return data;
  }

  Future<http.Response> _send(String path, String body, String? token) async {
    return _client
        .post(
          Uri.parse('$baseUrl$path'),
          headers: {
            'Content-Type': 'application/json',
            if (_clientId != null) 'X-Client-Id': await _clientId(),
            if (token != null) 'X-Device-Token': token,
          },
          body: body,
        )
        .timeout(_timeout);
  }

  UsageInfo? _usageOf(http.Response response) {
    try {
      return UsageInfo.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } catch (_) {
      return null;
    }
  }
}
