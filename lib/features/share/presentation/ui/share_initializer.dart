import 'dart:async';
import 'package:auto_diary_ai/features/share/presentation/ui/share_preview_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../../../../app.dart';
import '../../domain/entities/shared_post.dart';
import '../providers/share_provider.dart';

class ShareInitializer extends ConsumerStatefulWidget {
  const ShareInitializer({super.key});

  @override
  ConsumerState<ShareInitializer> createState() => _ShareInitializerState();
}

class _ShareInitializerState extends ConsumerState<ShareInitializer> {
  StreamSubscription<List<SharedMediaFile>>? _shareSubscription;

  @override
  void initState() {
    super.initState();
    _initializeShareIntent();
  }

  // ==========================
  // 共有処理
  // ==========================
  Future<void> _handleSharedUrl(String url) async {
    final shareService = ref.read(shareServiceProvider);

    final post = await shareService.handle(url);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) {
        return SharePreviewDialog(
          url: post.url,
          text: post.text,
          onConfirm: (selectedDate) {
            final useCase = ref.read(saveSharedPostUseCaseProvider);

            useCase.execute(
              url: post.url,
              text: post.text,
              receivedAt: selectedDate,
            );

            debugPrint('SAVED REQUEST SENT');

            // TODO: 保存UseCaseへ
          },
        );
      },
    );
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