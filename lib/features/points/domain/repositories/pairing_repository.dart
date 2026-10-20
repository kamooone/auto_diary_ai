import '../entities/pairing_session.dart';

/// Webのアカウントとの紐づけ(ポイントのサーバーとの通信)
abstract class PairingRepository {
  /// 紐づけコードを発行する。失敗した場合は例外
  /// [label]は、Webの確認画面に表示する、この端末の名前
  Future<PairingSession> start({required String label});

  /// Webで紐づけが確定したかを確認する。通信できない場合は例外
  Future<PairingClaimResult> claim(PairingSession session);

  /// サーバーに、この端末の紐づけの解除を伝える(Webの端末一覧からも消える)
  /// 通信できなくても例外にはしない(端末での解除は、そのまま進める)
  Future<void> unlink(String deviceToken);
}
