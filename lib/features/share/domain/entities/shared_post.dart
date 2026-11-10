class SharedPost {
  /// 保存済みの投稿を特定するID(保存前はnull)
  final int? id;

  final String url;
  final String text;
  final DateTime receivedAt;

  /// 結びつけた端末の写真のID
  final List<String> photoIds;

  SharedPost({
    this.id,
    required this.url,
    required this.text,
    required this.receivedAt,
    this.photoIds = const [],
  });
}
