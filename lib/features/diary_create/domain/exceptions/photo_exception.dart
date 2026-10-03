/// 写真へのアクセスが許可されていない
class PhotoPermissionException implements Exception {
  @override
  String toString() => 'PhotoPermissionException: 写真権限なし';
}
