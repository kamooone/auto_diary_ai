import 'package:auto_diary_ai/features/diary_create/domain/services/diary_copy_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('タイトルと本文を、空行で区切って1つの文章にする', () {
    expect(
      DiaryCopyText.format(title: '晴れの日', content: 'きょうは公園へ行った。'),
      '晴れの日\n\nきょうは公園へ行った。',
    );
  });

  test('前後の空白や改行は取り除く', () {
    expect(
      DiaryCopyText.format(title: ' 晴れの日\n', content: '\n本文です。 \n\n'),
      '晴れの日\n\n本文です。',
    );
  });

  test('タイトルが空の場合は、本文だけにする', () {
    expect(DiaryCopyText.format(title: '', content: '本文です。'), '本文です。');
  });

  test('本文が空の場合は、タイトルだけにする', () {
    expect(DiaryCopyText.format(title: '晴れの日', content: ' '), '晴れの日');
  });
}
