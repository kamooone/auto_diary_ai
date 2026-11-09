/// プッシュ通知の受け口(FirebaseのFCMを包む。テストでは偽物に差し替える)
abstract class PushMessagingGateway {
  /// この端末の通知の宛先(トークン)。通知が使えないときはnull
  Future<String?> getToken();

  /// 宛先が新しくなったとき
  Stream<String> get onTokenRefresh;

  /// アプリを開いている間に、通知が届いたとき
  Stream<void> get onForegroundMessage;

  /// 通知をタップして、アプリが開いたとき(アプリが裏にあったとき)
  Stream<void> get onNotificationOpened;

  /// 通知をタップして、アプリが起動したか(アプリが終了していたとき)
  Future<bool> openedFromNotification();
}
