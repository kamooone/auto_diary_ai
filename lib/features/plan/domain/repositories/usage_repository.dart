import '../entities/plan_type.dart';
import '../entities/usage_info.dart';

/// 今月のAIの使用量を、サーバーから取得する
abstract class UsageRepository {
  /// 取得できない場合(通信できない、サーバーが未対応など)はnull
  /// [plan]は、アプリが今のプランとして扱っているもの(上限の計算に使われる)
  Future<UsageInfo?> fetch({PlanType plan = PlanType.free});
}
