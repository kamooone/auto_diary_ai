/// アプリが発行した、Webとの紐づけコード
class PairingSession {
  /// 画面に表示して、Webで入力してもらう6桁のコード
  final String code;

  /// このアプリだけが持つ合言葉。画面には出さない
  /// (コードを見ただけの人が、端末用のトークンを横取りできないようにする)
  final String claimSecret;

  /// コードの有効期限
  final DateTime expiresAt;

  const PairingSession({
    required this.code,
    required this.claimSecret,
    required this.expiresAt,
  });

  bool get isExpired => !DateTime.now().isBefore(expiresAt);
}

/// 紐づけの確認の結果
sealed class PairingClaimResult {
  const PairingClaimResult();
}

/// まだWebで確定されていない
class PairingPending extends PairingClaimResult {
  const PairingPending();
}

/// コードの期限が切れた(または、すでに使われた)
class PairingExpired extends PairingClaimResult {
  const PairingExpired();
}

/// 紐づけが済んだ。端末用のトークンを受け取った(1回だけ受け取れる)
class PairingLinked extends PairingClaimResult {
  final String deviceToken;

  const PairingLinked(this.deviceToken);
}
