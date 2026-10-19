import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/entities/pairing_session.dart';
import '../domain/repositories/pairing_repository.dart';

class PairingException implements Exception {
  final String message;

  PairingException(this.message);

  @override
  String toString() => 'PairingException: $message';
}

class AwsPairingRepositoryImpl implements PairingRepository {
  final String baseUrl;
  final http.Client _client;

  AwsPairingRepositoryImpl(this.baseUrl, {http.Client? client})
      : _client = client ?? http.Client();

  static const _timeout = Duration(seconds: 10);

  @override
  Future<PairingSession> start({required String label}) async {
    final response = await _post('/pairing/start', {'label': label});

    if (response.statusCode != 200) {
      throw PairingException('start failed (${response.statusCode})');
    }

    final data = _decode(response);
    final code = data['code'];
    final secret = data['claimSecret'];
    final expiresAt = data['expiresAt'];

    if (code is! String || secret is! String || expiresAt is! num) {
      throw PairingException('unexpected response');
    }

    return PairingSession(
      code: code,
      claimSecret: secret,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
        expiresAt.toInt() * 1000,
      ),
    );
  }

  @override
  Future<PairingClaimResult> claim(PairingSession session) async {
    final response = await _post('/pairing/claim', {
      'code': session.code,
      'claimSecret': session.claimSecret,
    });

    // コードの期限切れ、またはすでに使われた
    if (response.statusCode == 404) return const PairingExpired();

    // まだWebで確定されていない
    if (response.statusCode == 202) return const PairingPending();

    if (response.statusCode != 200) {
      throw PairingException('claim failed (${response.statusCode})');
    }

    final token = _decode(response)['deviceToken'];
    if (token is! String || token.isEmpty) {
      throw PairingException('deviceToken is missing');
    }

    return PairingLinked(token);
  }

  Future<http.Response> _post(String path, Map<String, Object?> body) async {
    try {
      return await _client
          .post(
            Uri.parse('$baseUrl$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw PairingException('timeout: $path');
    } on http.ClientException catch (e) {
      throw PairingException('request failed: $path (${e.message})');
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is Map<String, dynamic>) return data;
    } on FormatException {
      // 下で例外にする
    }
    throw PairingException('unexpected response');
  }
}
