/// お問い合わせの送信・取得の失敗
class InquiryException implements Exception {
  const InquiryException(this.reason);

  final InquiryFailure reason;

  @override
  String toString() => 'InquiryException($reason)';
}

enum InquiryFailure {
  /// 1日に送れる件数を超えた
  tooMany,

  /// 通信できない・サーバーが対応していない・その他
  unavailable,
}
