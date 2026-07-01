import 'dart:async';
import 'package:auto_diary_ai/features/share/presentation/ui/share_preview_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../../application/providers/share_service_provider.dart';

class ShareInitializer extends ConsumerStatefulWidget {
  final Widget child;

  const ShareInitializer({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<ShareInitializer> createState() => _ShareInitializerState();
}

class _ShareInitializerState extends ConsumerState<ShareInitializer> {
  StreamSubscription<List<SharedMediaFile>>? _shareSubscription;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeShareIntent();
    });
  }

  // ==========================
  // 共有処理
  // ==========================
  Future<void> _handleSharedUrl(String url) async {

    final shareService = ref.read(shareServiceProvider);

    final post = await shareService.handle(url);

    if (!mounted) return;

    showDialog<DateTime>(
      context: context,
      builder: (_) {
        return SharePreviewDialog(
          url: post.url,
          text: post.text,
        );
      },
    ).then((selectedDate) async {
      if (selectedDate == null) return;

      await shareService.save(post, selectedDate);
    });
  }

  // ==========================
  // 初期化
  // ==========================
  Future<void> _initializeShareIntent() async {
    // ==========================
    // アプリ起動時のXからの共有を取得
    // ==========================
    final initialFiles = await ReceiveSharingIntent.instance.getInitialMedia();

    for (final file in initialFiles) {
      await _handleSharedUrl(file.path);
    }

    // ==========================
    // 共有されたファイルを受け取るストリームを監視(リスナー登録)
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
    return widget.child;
  }
}