import '../entities/pairing_session.dart';

/// Webのアカウントとの紐づけ(ポイントのサーバーとの通信)
abstract class PairingRepository {
  /// 紐づけコードを発行する。失敗した場合は例外
  /// [label]は、Webの確認画面に表示する、この端末の名前
  Future<PairingSession> start({required String label});

  /// Webで紐づけが確定したかを確認する。通信できない場合は例外
  Future<PairingClaimResult> claim(PairingSession session);
}
