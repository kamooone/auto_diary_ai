import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/app_info/app_version_provider.dart';
import '../../../../core/app_info/client_id.dart';
import '../../../ai/application/providers/ai_provider.dart';
import '../../data/aws_inquiry_repository_impl.dart';
import '../../data/file_inquiry_state_store.dart';
import '../../domain/entities/inquiry_message.dart';
import '../../domain/repositories/inquiry_repository.dart';

final inquiryRepositoryProvider = Provider<InquiryRepository>((ref) {
  return AwsInquiryRepositoryImpl(
    ref.watch(apiBaseUrlProvider),
    clientId: ClientId.get,
    appInfo: () => ref.read(appVersionProvider.future),
    platform: Platform.operatingSystem,
  );
});

final inquiryStateStoreProvider = Provider<InquiryStateStore>((ref) {
  return FileInquiryStateStore(() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/inquiry_state.json');
  });
});

/// 送った内容と、開発者からの返信(古い順)
/// 送信したあとは、ref.invalidate で読み込み直す
final inquiryMessagesProvider =
    FutureProvider.autoDispose<List<InquiryMessage>>((ref) {
      return ref.watch(inquiryRepositoryProvider).fetch();
    });

/// 開発者からの、まだ見ていない返信があるか
///
/// 一度も送っていない端末では、サーバーに問い合わせない。
/// 通信できないときなどは、お知らせしない(false)
final hasUnreadReplyProvider = FutureProvider.autoDispose<bool>((ref) async {
  final store = ref.watch(inquiryStateStoreProvider);
  final state = await store.load();
  if (!state.hasSent) return false;

  try {
    final messages = await ref.watch(inquiryRepositoryProvider).fetch();
    final latest = messages.where((e) => e.fromDeveloper).map((e) => e.createdAt);
    if (latest.isEmpty) return false;

    final newest = latest.reduce((a, b) => a.isAfter(b) ? a : b);
    final seen = state.seenReplyAt;

    return seen == null || newest.isAfter(seen);
  } catch (_) {
    return false;
  }
});
