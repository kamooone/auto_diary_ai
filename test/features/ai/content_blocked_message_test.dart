import 'package:auto_diary_ai/features/ai/domain/exceptions/ai_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const reason = 'AIに送れない内容(違法行為や暴力のやり方を求める内容など)が含まれている可能性があります';

  String messageOf(List<String> sources) =>
      ContentBlockedException(sources).message;

  test('どこが問題かが分からないときは、選んだ内容を見直す案内', () {
    expect(messageOf(const []), startsWith(reason));
    expect(messageOf(const []), endsWith('選んだ内容を見直してください。'));
    expect(messageOf(const ['unknown']), startsWith(reason));
  });

  test('入力ごとに、その場所を入れた案内になる', () {
    const expected = {
      'note': '「追加で伝えたいこと」',
      'customInstruction': '「書き方の指定」',
      'memosText': '「ひとことメモ」',
      'postsText': '選んだ「Xの投稿」',
      'timelineText': '選んだ「行動履歴」',
      'diariesText': '選んだ「日記」の内容',
      'message': '送った「メッセージ」',
    };

    for (final entry in expected.entries) {
      expect(
        messageOf([entry.key]),
        '${entry.value}に、$reason。内容を見直してください。',
        reason: entry.key,
      );
    }
  });

  test('複数のときは、名前を「と」でつなぐ。知らない名前は、飛ばす', () {
    expect(
      messageOf(const ['note', 'x', 'postsText']),
      '「追加で伝えたいこと」と選んだ「Xの投稿」に、$reason。内容を見直してください。',
    );
  });
}
