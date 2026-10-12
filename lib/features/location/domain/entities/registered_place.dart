/// ユーザーが場所名を入力して登録した場所
///
/// 同じ場所を訪れたときは、施設を検索せずに、登録した名前を表示する。
class RegisteredPlace {
  /// 保存前はnull
  final int? id;
  final double latitude;
  final double longitude;
  final String name;

  const RegisteredPlace({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.name,
  });

  RegisteredPlace copyWith({String? name}) {
    return RegisteredPlace(
      id: id,
      latitude: latitude,
      longitude: longitude,
      name: name ?? this.name,
    );
  }
}
