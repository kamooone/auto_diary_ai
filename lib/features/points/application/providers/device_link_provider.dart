import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/secure_device_token_store.dart';
import '../../domain/repositories/device_token_store.dart';

final deviceTokenStoreProvider = Provider<DeviceTokenStore>((ref) {
  return SecureDeviceTokenStore();
});

/// Webのアカウントと紐づけ済みか(読み込みが終わるまではfalse)
final deviceLinkProvider =
    NotifierProvider<DeviceLinkNotifier, bool>(DeviceLinkNotifier.new);

class DeviceLinkNotifier extends Notifier<bool> {
  var _isDisposed = false;

  // 読み込みが終わる前に変更した場合は、遅れて届いた読み込み結果で上書きしない
  var _isChanged = false;

  @override
  bool build() {
    ref.onDispose(() => _isDisposed = true);
    _load();
    return false;
  }

  Future<void> _load() async {
    final token = await ref.read(deviceTokenStoreProvider).load();
    if (!_isDisposed && !_isChanged) state = token != null;
  }

  /// APIに付ける端末用のトークン(紐づけていなければnull)
  Future<String?> token() => ref.read(deviceTokenStoreProvider).load();

  /// 紐づけが済んだときに、受け取ったトークンを保存する
  Future<void> link(String token) async {
    _isChanged = true;
    await ref.read(deviceTokenStoreProvider).save(token);
    state = true;
  }

  /// 端末のトークンを捨てる(Webで解除された、またはアプリで解除した)
  Future<void> unlink() async {
    _isChanged = true;
    await ref.read(deviceTokenStoreProvider).clear();
    state = false;
  }
}
