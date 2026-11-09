import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/repositories/push_token_repository.dart';

/// 通知の宛先(トークン)を、AWSのサーバーに登録する
class AwsPushTokenRepositoryImpl implements PushTokenRepository {
  AwsPushTokenRepositoryImpl(
    this.baseUrl, {
    required Future<String> Function() clientId,
    http.Client? client,
  }) : _clientId = clientId,
       _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  // 端末を識別する匿名のID
  final Future<String> Function() _clientId;

  static const _path = '/push-token';
  static const _timeout = Duration(seconds: 15);

  @override
  Future<void> register(String token) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl$_path'),
          headers: {
            'X-Client-Id': await _clientId(),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'token': token}),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw http.ClientException('push token: ${response.statusCode}');
    }
  }
}
