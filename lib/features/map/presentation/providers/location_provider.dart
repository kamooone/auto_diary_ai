import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_diary_ai/core/database/isar_provider.dart';
import 'package:auto_diary_ai/features/map/data/repositories/location_repository.dart';
import 'package:auto_diary_ai/features/map/data/services/location_service.dart';


/// LocationRepositoryのProvider
///
/// 役割
/// ・位置情報DB操作クラスを生成する
/// ・IsarデータベースをRepositoryへ注入する
///
/// 依存関係
/// isarProvider → LocationRepository
///
/// Repositoryは
/// ・DB保存
/// ・DB取得
/// などのデータアクセス層を担当する
final locationRepositoryProvider = Provider<LocationRepository>((ref) {

  // Isar DBインスタンスを取得
  final isar = ref.watch(isarProvider);

  // Repository生成（DBを注入）
  return LocationRepository(isar);
});


/// LocationServiceのProvider
///
/// 役割
/// ・位置情報取得ロジックを提供する
/// ・RepositoryをServiceへ注入する
///
/// 依存関係
/// locationRepositoryProvider → LocationService
///
/// Serviceは
/// ・GPS取得
/// ・DB保存処理の呼び出し
/// ・Stream配信
/// などアプリのビジネスロジックを担当する
final locationServiceProvider = Provider<LocationService>((ref) {

  // Repository取得
  final repo = ref.watch(locationRepositoryProvider);

  // Service生成
  return LocationService(repo);
});
