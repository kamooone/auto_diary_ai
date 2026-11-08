import 'package:auto_diary_ai/features/diary_create/domain/services/generated_diary_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final parser = GeneratedDiaryParser();

  test('タイトルと本文に分ける', () {
    final diary = parser.parse('''
タイトル: 秋の散歩
本文:
今日は公園を歩いた。

紅葉がきれいだった。
''');

    expect(diary.title, '秋の散歩');
    expect(diary.content, '今日は公園を歩いた。\n\n紅葉がきれいだった。');
  });

  test('全角のコロンや飾りが付いていても取り出す', () {
    final diary = parser.parse('**タイトル：** 「秋の散歩」\n\n**本文：**\n今日は公園を歩いた。');

    expect(diary.title, '秋の散歩');
    expect(diary.content, '今日は公園を歩いた。');
  });

  test('「本文:」の行がなくても、タイトルの後ろを本文にする', () {
    final diary = parser.parse('タイトル: 秋の散歩\n\n今日は公園を歩いた。');

    expect(diary.title, '秋の散歩');
    expect(diary.content, '今日は公園を歩いた。');
  });

  test('「本文:」と同じ行に書かれた文も本文に含める', () {
    final diary = parser.parse('タイトル: 秋の散歩\n本文: 今日は公園を歩いた。\n楽しかった。');

    expect(diary.content, '今日は公園を歩いた。\n楽しかった。');
  });

  test('形式に従っていない場合は、全体を本文にする', () {
    final diary = parser.parse('今日は公園を歩いた。\nタイトル: これは本文の一部');

    expect(diary.title, '');
    expect(diary.content, '今日は公園を歩いた。\nタイトル: これは本文の一部');
  });
}
