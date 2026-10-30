import 'package:auto_diary_ai/features/setting/domain/services/test_diary_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final diaries = TestDiaryGenerator.generate(
    first: DateTime(2026, 1, 1),
    last: DateTime(2026, 10, 27),
  );

  test('1月1日から10月27日まで、1日1件(300件)', () {
    expect(diaries.length, 300);
    expect(diaries.first.date, DateTime(2026, 1, 1));
    expect(diaries.last.date, DateTime(2026, 10, 27));
  });

  test('各日記は500文字前後で、テスト用と見分けられる', () {
    for (final d in diaries) {
      expect(d.content.length, inInclusiveRange(350, 650));
      expect(TestDiaryGenerator.isTestDiary(d), isTrue);
    }
  });

  test('日によって内容が変わる', () {
    expect(diaries[0].content, isNot(diaries[1].content));
  });
}
