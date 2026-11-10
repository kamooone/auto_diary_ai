class Photo {
  final String id;
  final DateTime createdAt;

  /// 向きを直した後の縦横の大きさ(分からないときはnull)
  final int? width;
  final int? height;

  const Photo({
    required this.id,
    required this.createdAt,
    this.width,
    this.height,
  });
}
