/// アプリのプラン(無料と有料)
enum PlanType {
  free('無料プラン'),
  paid('有料プラン');

  const PlanType(this.label);

  final String label;

  bool get isPaid => this == PlanType.paid;
}
