/// Webのアカウントと紐づけたときに受け取った、端末用のトークンの保存先
///
/// トークンは、アカウントのトークン残高を使うための鍵のため、
/// 端末の安全な保存領域(Keystore・Keychain)に保存する。
abstract class DeviceTokenStore {
  /// 保存されていない場合、または読み出せない場合はnull
  Future<String?> load();

  Future<void> save(String token);

  Future<void> clear();
}
