/// お問い合わせの種類(サーバーには[value]を送る)
enum InquiryCategory {
  bug('bug', '不具合'),
  request('request', '要望'),
  other('other', 'その他');

  const InquiryCategory(this.value, this.label);

  final String value;
  final String label;

  static InquiryCategory? fromValue(Object? value) {
    return InquiryCategory.values.where((e) => e.value == value).firstOrNull;
  }
}
