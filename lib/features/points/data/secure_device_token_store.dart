import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../domain/repositories/device_token_store.dart';

/// Keystore(Android)・Keychain(iOS)に、端末用のトークンを保存する
class SecureDeviceTokenStore implements DeviceTokenStore {
  final FlutterSecureStorage _storage;

  SecureDeviceTokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'device_token';

  @override
  Future<String?> load() async {
    try {
      final token = await _storage.read(key: _key);
      return token == null || token.isEmpty ? null : token;
    } catch (_) {
      // 復号できない場合(バックアップの復元など)は、未紐づけとして扱う
      return null;
    }
  }

  @override
  Future<void> save(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {
      // 消せなくても、読み出せない状態なら、未紐づけとして扱われる
    }
  }
}
