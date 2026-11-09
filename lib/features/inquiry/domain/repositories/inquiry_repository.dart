import '../entities/inquiry_category.dart';
import '../entities/inquiry_message.dart';

abstract class InquiryRepository {
  /// 問い合わせを送る。失敗したら[InquiryException]
  Future<InquiryMessage> send({
    required InquiryCategory category,
    required String message,
  });

  /// 自分が送った内容と、開発者からの返信を、古い順に取得する。失敗したら[InquiryException]
  Future<List<InquiryMessage>> fetch();
}
