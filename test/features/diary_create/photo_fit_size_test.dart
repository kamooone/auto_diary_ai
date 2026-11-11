import 'package:auto_diary_ai/features/diary_create/data/repositories/photo_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PhotoRepositoryImpl.fitSize', () {
    test('横長は、長辺(幅)を1024にそろえる', () {
      final size = PhotoRepositoryImpl.fitSize(4000, 2250, 1024);
      expect(size.width, 1024);
      expect(size.height, 576);
    });

    test('縦長(向きを直した後の縦横)は、長辺(高さ)を1024にそろえる', () {
      final size = PhotoRepositoryImpl.fitSize(2250, 4000, 1024);
      expect(size.width, 576);
      expect(size.height, 1024);
    });

    test('4:3も、長辺が1024になる', () {
      final landscape = PhotoRepositoryImpl.fitSize(4000, 3000, 1024);
      expect(landscape.width, 1024);
      expect(landscape.height, 768);

      final portrait = PhotoRepositoryImpl.fitSize(3000, 4000, 1024);
      expect(portrait.width, 768);
      expect(portrait.height, 1024);
    });

    test('かなり縦長でも、長辺が1024を超えない', () {
      final size = PhotoRepositoryImpl.fitSize(856, 2000, 1024);
      expect(size.width, 438);
      expect(size.height, 1024);
    });

    test('小さい写真は、拡大しない', () {
      final size = PhotoRepositoryImpl.fitSize(640, 480, 1024);
      expect(size.width, 640);
      expect(size.height, 480);
    });

    test('大きさが分からないときは、正方形で頼む', () {
      final size = PhotoRepositoryImpl.fitSize(0, 0, 1024);
      expect(size.width, 1024);
      expect(size.height, 1024);
    });

    test('長辺が違う縮小サイズ(表示用の2048・4096)でも同じ規則', () {
      final size = PhotoRepositoryImpl.fitSize(2250, 4000, 2048);
      expect(size.width, 1152);
      expect(size.height, 2048);
    });
  });
}
