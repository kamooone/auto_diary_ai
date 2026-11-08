import 'package:auto_diary_ai/features/diary/domain/entities/diary.dart';
import 'package:auto_diary_ai/features/setting/domain/services/test_diary_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final diaries = TestDiaryGenerator.generate(
    first: DateTime(2026, 1, 1),
    last: DateTime(2026, 10, 27),
  );

  Diary on(int month, int day) => diaries.firstWhere(
    (e) => e.date == DateTime(2026, month, day),
  );

  test('1月1日から10月27日まで、1日1件(300件)', () {
    expect(diaries.length, 300);
    expect(diaries.first.date, DateTime(2026, 1, 1));
    expect(diaries.last.date, DateTime(2026, 10, 27));
  });

  test('各日記は200〜900文字で、テスト用と見分けられる', () {
    for (final d in diaries) {
      expect(d.content.length, inInclusiveRange(150, 900), reason: '${d.date}');
      expect(TestDiaryGenerator.isTestDiary(d), isTrue);
    }
  });

  test('日によって内容が変わり、同じ日に同じ文が2回入らない', () {
    expect(diaries[0].content, isNot(diaries[1].content));

    for (final d in diaries) {
      final sentences = d.content.split('。').where((e) => e.isNotEmpty);
      expect(sentences.toSet().length, sentences.length, reason: '${d.date}');
    }
  });

  test('決まった日には、その日だけの出来事が入る', () {
    expect(on(1, 1).content, contains('初詣'));
    expect(on(1, 15).content, contains('リーダー'));
    expect(on(5, 3).content, contains('京都'));
    expect(on(7, 18).content, contains('リリース'));
    expect(on(10, 11).content, contains('10キロ'));
    expect(on(5, 3).title, contains('京都'));
  });

  test('平日は仕事の題、休日は休日の題になる', () {
    // 2026年1月5日は月曜、1月3日は土曜
    expect(on(1, 5).title, isNot(contains('休日')));
    expect(on(1, 3).content, isNot(contains('出勤')));
  });
}
