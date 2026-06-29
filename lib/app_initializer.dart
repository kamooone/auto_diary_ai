import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

import 'app.dart';

class AppInitializer extends ConsumerStatefulWidget {
  const AppInitializer({super.key});

  @override
  ConsumerState<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends ConsumerState<AppInitializer> {
  StreamSubscription<List<SharedMediaFile>>? _shareSubscription;

  @override
  void initState() {
    super.initState();
    _initializeShareIntent();
  }

  // ==========================
  // OGPからテキスト取得
  // ==========================
  Future<String?> _fetchTweetText(String url) async {
    try {
      final res = await http.get(Uri.parse(url));

      if (res.statusCode != 200) return null;

      final doc = parser.parse(res.body);

      final meta = doc.querySelector(
        'meta[property="og:description"]',
      );

      return meta?.attributes['content'];
    } catch (e) {
      debugPrint('OGP fetch error: $e');
      return null;
    }
  }

  // ==========================
  // 共有処理
  // ==========================
  Future<void> _handleSharedUrl(String url) async {
    final receivedAt = DateTime.now().toUtc();

    debugPrint('===== Shared URL =====');
    debugPrint(url);

    final text = await _fetchTweetText(url);

    final payload = {
      'url': url,
      'text': text ?? '',
      'received_at': receivedAt.toIso8601String(),
      'source': text != null ? 'ogp' : 'fallback',
    };

    debugPrint('===== Extracted Data =====');
    debugPrint('URL         : $url');
    debugPrint('Text        : $text');
    debugPrint('Received At : $receivedAt');
    debugPrint('Payload     : $payload');

    // TODO: ここで日記生成AIに渡す
  }

  // ==========================
  // 初期化
  // ==========================
  Future<void> _initializeShareIntent() async {
    // ==========================
    // アプリ起動時の共有
    // ==========================
    final initialFiles =
    await ReceiveSharingIntent.instance.getInitialMedia();

    for (final file in initialFiles) {
      await _handleSharedUrl(file.path);
    }

    // ==========================
    // アプリ起動中の共有
    // ==========================
    _shareSubscription =
        ReceiveSharingIntent.instance.getMediaStream().listen(
              (sharedFiles) async {
            for (final file in sharedFiles) {
              await _handleSharedUrl(file.path);
            }
          },
          onError: (error) {
            debugPrint('Share Error: $error');
          },
        );
  }

  @override
  void dispose() {
    _shareSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const App();
  }
}