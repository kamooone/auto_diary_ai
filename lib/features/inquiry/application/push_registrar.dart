import 'dart:async';
import '../data/file_inquiry_state_store.dart';
import '../domain/repositories/push_token_repository.dart';
import '../domain/services/push_messaging_gateway.dart';

/// お問い合わせの返信の通知を受け取るための、宛先の登録と、通知を受けたときの動き
///
/// - **一度でもお問い合わせを送った端末だけ**が、宛先をサーバーに登録する
///   (送っていない人の宛先は、サーバーに送らない)
/// - 通知をタップしたときは、[onOpenInquiry]でお問い合わせの画面を開く
/// - アプリを開いている間に通知が届いたときは、[onReplyArrived]で画面の表示を更新する
class PushRegistrar {
  PushRegistrar({
    required this.gateway,
    required this.tokens,
    required this.store,
    required this.onOpenInquiry,
    required this.onReplyArrived,
  });

  final PushMessagingGateway gateway;
  final PushTokenRepository tokens;
  final InquiryStateStore store;
  final void Function() onOpenInquiry;
  final void Function() onReplyArrived;

  final _subscriptions = <StreamSubscription<Object?>>[];
  var _started = false;

  /// アプリの起動時に1回だけ呼ぶ
  Future<void> start() async {
    if (_started) return;
    _started = true;

    _subscriptions
      ..add(gateway.onTokenRefresh.listen((token) => _register(token)))
      ..add(gateway.onForegroundMessage.listen((_) => onReplyArrived()))
      ..add(gateway.onNotificationOpened.listen((_) => onOpenInquiry()));

    if (await gateway.openedFromNotification()) onOpenInquiry();

    await sync();
  }

  /// 送ったことがあれば、今の宛先をサーバーに登録する(失敗しても、アプリは止めない)
  Future<void> sync() async {
    try {
      if (!(await store.load()).hasSent) return;

      final token = await gateway.getToken();
      if (token != null) await _register(token);
    } catch (_) {
      // 通知が使えない・通信できないときは、次の起動のときに、もう一度試す
    }
  }

  Future<void> _register(String token) async {
    try {
      if (!(await store.load()).hasSent) return;
      await tokens.register(token);
    } catch (_) {
      // 次の起動のときに、もう一度試す
    }
  }

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }
}
