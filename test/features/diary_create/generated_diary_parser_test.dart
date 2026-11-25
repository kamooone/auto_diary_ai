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

  test('英語の見出し(Title・本文)で返ってきても、タイトルを取り出す', () {
    // GPTが、「Title:」で返したことがある(2026-11-25)。タイトルが空になっていた
    final diary = parser.parse(
      'Title: 静かな朝から始まった満ち足りた一日\n\n本文:\n朝六時に目が覚めた。\n\n夜は炒め物を作った。',
    );

    expect(diary.title, '静かな朝から始まった満ち足りた一日');
    expect(diary.content, '朝六時に目が覚めた。\n\n夜は炒め物を作った。');
  });

  test('英語の見出し(Title・Body)や、小文字・飾りがあっても、取り出す', () {
    final diary = parser.parse('**TITLE:** 秋の散歩\nbody: 今日は公園を歩いた。');

    expect(diary.title, '秋の散歩');
    expect(diary.content, '今日は公園を歩いた。');
  });

  test('本文の途中の「Title:」は、タイトルにしない', () {
    final diary = parser.parse('今日は公園を歩いた。\nTitle: これは本文の一部');

    expect(diary.title, '');
    expect(diary.content, '今日は公園を歩いた。\nTitle: これは本文の一部');
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
