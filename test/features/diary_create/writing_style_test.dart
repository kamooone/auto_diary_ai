import 'dart:io';
import 'package:auto_diary_ai/features/diary_create/data/repositories/file_writing_style_repository.dart';
import 'package:auto_diary_ai/features/diary_create/domain/services/writing_style.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  late FileWritingStyleRepository repository;

  setUp(() {
    dir = Directory.systemTemp.createTempSync();
    repository = FileWritingStyleRepository(
      () async => File('${dir.path}/style.json'),
    );
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('保存していなければ、サンプル文が返る', () async {
    expect(await repository.load(), WritingStyle.defaultText);
  });

  test('保存した文章が返り、サンプルに戻せる', () async {
    await repository.save('一人称は俺');
    expect(await repository.load(), '一人称は俺');

    await repository.reset();
    expect(await repository.load(), WritingStyle.defaultText);
  });

  test('空にして保存したら、空のまま(希望なし)', () async {
    await repository.save('');
    expect(await repository.load(), '');
  });

  test('希望が空なら、プロンプトに何も差し込まない', () {
    expect(WritingStyle.section('  '), '');
    expect(WritingStyle.section('俺'), contains('俺'));
  });
}
