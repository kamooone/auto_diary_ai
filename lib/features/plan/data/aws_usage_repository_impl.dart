import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/entities/plan_type.dart';
import '../domain/entities/usage_info.dart';
import '../domain/repositories/usage_repository.dart';

/// 今月のAIの使用量を、AWSのサーバーから取得する
class AwsUsageRepositoryImpl implements UsageRepository {
  final String baseUrl;
  final http.Client _client;

  // 端末を識別する匿名のID
  final Future<String> Function() _clientId;

  // Webのアカウントと紐づけたときの、端末用のトークン(紐づけていなければnull)
  final Future<String?> Function()? _deviceToken;

  // サーバーに端末用のトークンを断られた(解除された)ときに呼ぶ
  final Future<void> Function()? _onInvalidDeviceToken;

  AwsUsageRepositoryImpl(
    this.baseUrl, {
    required Future<String> Function() clientId,
    Future<String?> Function()? deviceToken,
    Future<void> Function()? onInvalidDeviceToken,
    http.Client? client,
  })  : _clientId = clientId,
        _deviceToken = deviceToken,
        _onInvalidDeviceToken = onInvalidDeviceToken,
        _client = client ?? http.Client();

  static const _usagePath = '/plan/usage';

  static const _timeout = Duration(seconds: 10);

  @override
  Future<UsageInfo?> fetch({PlanType plan = PlanType.free}) async {
    try {
      var token = await _deviceToken?.call();
      var response = await _get(plan, token);

      // 紐づけが解除されている。トークンを捨てて、紐づけなしで取得し直す
      if (response.statusCode == 401 && token != null) {
        await _onInvalidDeviceToken?.call();
        token = null;
        response = await _get(plan, token);
      }

      // サーバーが未対応の場合なども、使用量は分からないものとして扱う
      if (response.statusCode != 200) return null;

      return UsageInfo.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } on TimeoutException {
      return null;
    } on http.ClientException {
      return null;
    } on FormatException {
      return null;
    }
  }

  Future<http.Response> _get(PlanType plan, String? token) async {
    return _client.get(
      Uri.parse('$baseUrl$_usagePath').replace(
        queryParameters: {'plan': plan.name},
      ),
      headers: {
        'X-Client-Id': await _clientId(),
        if (token != null) 'X-Device-Token': token,
      },
    ).timeout(_timeout);
  }
}
