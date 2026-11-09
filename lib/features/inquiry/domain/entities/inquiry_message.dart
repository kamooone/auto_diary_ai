import 'inquiry_category.dart';

/// お問い合わせのやり取りの1件(自分が送ったもの、または開発者からの返信)
class InquiryMessage {
  const InquiryMessage({
    required this.id,
    required this.fromDeveloper,
    required this.text,
    required this.createdAt,
    this.category,
  });

  final String id;
  final bool fromDeveloper;
  final String text;
  final DateTime createdAt;

  /// 自分が送ったものだけ
  final InquiryCategory? category;

  /// サーバーの応答の1件分から作る。形が違うときはnull
  static InquiryMessage? fromJson(Object? json) {
    if (json is! Map) return null;

    final id = json['id'];
    final text = json['message'];
    final createdAt = DateTime.tryParse('${json['createdAt']}');

    if (id is! String || text is! String || createdAt == null) return null;

    return InquiryMessage(
      id: id,
      fromDeveloper: json['from'] == 'developer',
      text: text,
      createdAt: createdAt.toLocal(),
      category: InquiryCategory.fromValue(json['category']),
    );
  }
}
