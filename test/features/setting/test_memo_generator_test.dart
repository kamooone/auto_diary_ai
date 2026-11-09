import 'package:auto_diary_ai/features/memo/domain/entities/memo.dart';
import 'package:auto_diary_ai/features/setting/domain/services/test_memo_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final first = DateTime(2026, 1, 1);
  final last = DateTime(2026, 10, 27);
  final memos = TestMemoGenerator.generate(first: first, last: last);

  test('日記と同じ期間に、300件以上できる', () {
    expect(memos.length, inInclusiveRange(300, 600));
    expect(
      memos.every(
        (e) =>
            !e.createdAt.isBefore(first) &&
            e.createdAt.isBefore(DateTime(2026, 10, 28)),
      ),
      isTrue,
    );
  });

  test('すべてテスト用と見分けられ、文字数の上限に収まる', () {
    expect(memos.every(TestMemoGenerator.isTestMemo), isTrue);
    expect(memos.every((e) => e.text.length <= Memo.maxLength), isTrue);
    expect(
      TestMemoGenerator.isTestMemo(
        Memo(text: 'ふつうのメモ', createdAt: DateTime(2026, 1, 1)),
      ),
      isFalse,
    );
  });

  test('同じ日の同じ文は重ならず、いつも同じ内容ができる', () {
    final byDay = <DateTime, Set<String>>{};
    for (final m in memos) {
      final day = DateTime(m.createdAt.year, m.createdAt.month, m.createdAt.day);
      expect(byDay.putIfAbsent(day, () => {}).add(m.text), isTrue);
    }

    final again = TestMemoGenerator.generate(first: first, last: last);
    expect(again.map((e) => e.text), memos.map((e) => e.text));
  });
}
