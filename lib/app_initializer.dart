import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

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

  Future<void> _initializeShareIntent() async {
    // ==========================
    // アプリが終了していた状態から共有された場合
    // ==========================
    final initialFiles =
    await ReceiveSharingIntent.instance.getInitialMedia();

    if (initialFiles.isNotEmpty) {
      debugPrint('===== Initial Share =====');

      for (final file in initialFiles) {
        debugPrint('Path    : ${file.path}');
        debugPrint('Type    : ${file.type}');
        debugPrint('Message : ${file.message}');
        debugPrint('-------------------------');
      }
    }

    // ==========================
    // アプリ起動中に共有された場合
    // ==========================
    _shareSubscription =
        ReceiveSharingIntent.instance.getMediaStream().listen(
              (sharedFiles) {
            debugPrint('===== Share Stream =====');

            for (final file in sharedFiles) {
              debugPrint('Path    : ${file.path}');
              debugPrint('Type    : ${file.type}');
              debugPrint('Message : ${file.message}');
              debugPrint('-------------------------');
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