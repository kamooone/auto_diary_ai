abstract class PushTokenRepository {
  /// この端末の通知の宛先(トークン)を、サーバーに登録する。失敗したら例外
  Future<void> register(String token);
}
