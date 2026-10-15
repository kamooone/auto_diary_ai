import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/entities/usage_info.dart';
import '../domain/repositories/usage_repository.dart';

/// 今月の使用量を、AWSのサーバーから取得する
class AwsUsageRepositoryImpl implements UsageRepository {
  final String baseUrl;
  final http.Client _client;

  // 端末を識別する匿名のID
  final Future<String> Function() _clientId;

  AwsUsageRepositoryImpl(
    this.baseUrl, {
    required Future<String> Function() clientId,
    http.Client? client,
  })  : _clientId = clientId,
        _client = client ?? http.Client();

  static const _usagePath = '/plan/usage';

  static const _timeout = Duration(seconds: 10);

  @override
  Future<UsageInfo?> fetch() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl$_usagePath'),
        headers: {'X-Client-Id': await _clientId()},
      ).timeout(_timeout);

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
}
