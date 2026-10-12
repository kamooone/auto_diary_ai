import '../entities/registered_place.dart';

abstract class RegisteredPlaceRepository {
  /// 登録した場所をすべて取得
  Future<List<RegisteredPlace>> getAll();

  /// 場所を保存(idがある場合は上書き)
  Future<void> save(RegisteredPlace place);

  Future<void> delete(int id);
}
