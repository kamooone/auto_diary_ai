import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/entities/inquiry_category.dart';
import '../domain/entities/inquiry_exception.dart';
import '../domain/entities/inquiry_message.dart';
import '../domain/repositories/inquiry_repository.dart';

/// お問い合わせを、AWSのサーバーに送る・受け取る
class AwsInquiryRepositoryImpl implements InquiryRepository {
  AwsInquiryRepositoryImpl(
    this.baseUrl, {
    required Future<String> Function() clientId,
    required Future<String> Function() appInfo,
    required String platform,
    http.Client? client,
  }) : _clientId = clientId,
       _appInfo = appInfo,
       _platform = platform,
       _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  // 端末を識別する匿名のID
  final Future<String> Function() _clientId;

  // 「1.0.0 (111)」の形のアプリのバージョン
  final Future<String> Function() _appInfo;

  // 「android」など(不具合の調査に使う)
  final String _platform;

  static const _path = '/inquiries';
  static const _timeout = Duration(seconds: 15);

  Future<Map<String, String>> _headers() async => {
    'X-Client-Id': await _clientId(),
    'Content-Type': 'application/json',
  };

  @override
  Future<InquiryMessage> send({
    required InquiryCategory category,
    required String message,
  }) async {
    final response = await _request(
      () async => _client
          .post(
            Uri.parse('$baseUrl$_path'),
            headers: await _headers(),
            body: jsonEncode({
              'category': category.value,
              'message': message,
              'appVersion': await _appInfo(),
              'platform': _platform,
            }),
          )
          .timeout(_timeout),
    );

    final sent = InquiryMessage.fromJson(_decode(response)['message']);
    if (sent == null) throw const InquiryException(InquiryFailure.unavailable);

    return sent;
  }

  @override
  Future<List<InquiryMessage>> fetch() async {
    final response = await _request(
      () async => _client
          .get(Uri.parse('$baseUrl$_path'), headers: await _headers())
          .timeout(_timeout),
    );

    final list = _decode(response)['messages'];
    if (list is! List) throw const InquiryException(InquiryFailure.unavailable);

    return list.map(InquiryMessage.fromJson).whereType<InquiryMessage>().toList();
  }

  Future<http.Response> _request(Future<http.Response> Function() send) async {
    final http.Response response;

    try {
      response = await send();
    } on TimeoutException {
      throw const InquiryException(InquiryFailure.unavailable);
    } on http.ClientException {
      throw const InquiryException(InquiryFailure.unavailable);
    }

    if (response.statusCode == 429) {
      throw const InquiryException(InquiryFailure.tooMany);
    }
    if (response.statusCode != 200) {
      throw const InquiryException(InquiryFailure.unavailable);
    }

    return response;
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is Map<String, dynamic>) return data;
    } on FormatException {
      // 下で例外にする
    }
    throw const InquiryException(InquiryFailure.unavailable);
  }
}
