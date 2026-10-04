/// 日記作成の制限(プランごとに変わる)
class DiaryPlan {
  /// 1回の日記で対象にできる日数
  final int maxDays;

  /// 1回の日記でAIに渡せる写真の枚数
  final int maxPhotos;

  const DiaryPlan({
    required this.maxDays,
    required this.maxPhotos,
  });

  /// 無課金(標準)
  static const free = DiaryPlan(maxDays: 1, maxPhotos: 10);
}
