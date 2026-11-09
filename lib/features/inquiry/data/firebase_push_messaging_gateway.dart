import 'package:firebase_messaging/firebase_messaging.dart';
import '../domain/services/push_messaging_gateway.dart';

/// [PushMessagingGateway]の、Firebase(FCM)による実装
///
/// 宛先は、従来のFCMトークンを使う(firebase_messaging 17で「非推奨」になった方式だが、
/// 新しい方式(FID)は、サーバーからの送り方も変わる新しい仕組みのため、実績のあるこちらにしている)
class FirebasePushMessagingGateway implements PushMessagingGateway {
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  @override
  // ignore: deprecated_member_use
  Future<String?> getToken() => _messaging.getToken();

  @override
  // ignore: deprecated_member_use
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Stream<void> get onForegroundMessage => FirebaseMessaging.onMessage;

  @override
  Stream<void> get onNotificationOpened =>
      FirebaseMessaging.onMessageOpenedApp;

  @override
  Future<bool> openedFromNotification() async =>
      await _messaging.getInitialMessage() != null;
}
