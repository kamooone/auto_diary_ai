import 'dart:convert';
import 'dart:io';

/// お問い合わせについて、この端末で覚えておくこと
///
/// - 一度でも送ったか(送った端末だけが、返信の確認をする)
/// - どの返信まで見たか(新しい返信のお知らせに使う)
class InquiryState {
  const InquiryState({this.hasSent = false, this.seenReplyAt});

  final bool hasSent;

  /// 最後に画面で見た、開発者からの返信の日時
  final DateTime? seenReplyAt;
}

abstract class InquiryStateStore {
  Future<InquiryState> load();

  Future<void> markSent();

  /// [replyAt]までの返信を見たことにする(それより古い日時には戻さない)
  Future<void> markSeen(DateTime replyAt);
}

/// [InquiryState]を、端末内のファイルに保存する
class FileInquiryStateStore implements InquiryStateStore {
  // アプリのデータ用フォルダは非同期で決まるため、読み書きのときに解決する
  FileInquiryStateStore(this._resolveFile);

  final Future<File> Function() _resolveFile;

  @override
  Future<InquiryState> load() async {
    try {
      final file = await _resolveFile();
      if (!await file.exists()) return const InquiryState();

      final data = jsonDecode(await file.readAsString());
      if (data is! Map) return const InquiryState();

      return InquiryState(
        hasSent: data['hasSent'] == true,
        seenReplyAt: DateTime.tryParse('${data['seenReplyAt']}'),
      );
    } catch (_) {
      return const InquiryState();
    }
  }

  Future<void> _save(InquiryState state) async {
    final file = await _resolveFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode({
        'hasSent': state.hasSent,
        if (state.seenReplyAt != null)
          'seenReplyAt': state.seenReplyAt!.toUtc().toIso8601String(),
      }),
    );
  }

  @override
  Future<void> markSent() async {
    final state = await load();
    await _save(InquiryState(hasSent: true, seenReplyAt: state.seenReplyAt));
  }

  @override
  Future<void> markSeen(DateTime replyAt) async {
    final state = await load();
    final seen = state.seenReplyAt;
    if (seen != null && !replyAt.isAfter(seen)) return;

    await _save(InquiryState(hasSent: state.hasSent, seenReplyAt: replyAt));
  }
}
