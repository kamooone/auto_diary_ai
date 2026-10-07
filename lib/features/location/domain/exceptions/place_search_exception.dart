/// 周辺の施設の検索に失敗した(通信できない、検索サービスが応答しないなど)
class PlaceSearchException implements Exception {
  final String message;

  PlaceSearchException(this.message);

  @override
  String toString() => 'PlaceSearchException: $message';
}
