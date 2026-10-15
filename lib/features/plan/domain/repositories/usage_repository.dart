import '../entities/usage_info.dart';

/// 今月のAIの使用量を、サーバーから取得する
abstract class UsageRepository {
  /// 取得できない場合(通信できない、サーバーが未対応など)はnull
  Future<UsageInfo?> fetch();
}
