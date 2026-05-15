import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';


/// IsarデータベースのProvider
/// アプリ全体で同一のIsarインスタンスを共有するためのProvider。
///
/// このProvider自体ではIsarを生成しない。
/// Isarは非同期 (`Isar.open()`) で初期化する必要があるため、
/// `main()` 内で生成したインスタンスを `ProviderScope.overrides` で注入する。
///
/// こうすることで、RepositoryやServiceなどから
/// final isar = ref.watch(isarProvider);
/// のようにしてDBインスタンスへアクセスできる。
///
/// `throw UnimplementedError()` は
/// 「overrideされずにこのProviderが直接呼ばれた場合はエラーにする」
/// ための安全対策。
final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError();
});