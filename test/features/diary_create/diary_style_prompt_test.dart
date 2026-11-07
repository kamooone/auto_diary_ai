import 'package:auto_diary_ai/features/diary_create/domain/entities/diary_style.dart';
import 'package:auto_diary_ai/features/diary_create/domain/services/diary_style_prompt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String diary({required bool multi}) => DiaryStylePrompt.section(
    style: DiaryStyle.diary,
    customInstruction: '',
    isMultiDay: multi,
  );

  test('複数日の日記は、数日のとき、どの日も省かず、行動履歴の細部も入れる指示がある', () {
    final text = diary(multi: true);

    expect(text, contains('どの日も省かずに'));
    expect(text, contains('行動履歴の場所や滞在も'));
  });

  test('1日の日記には、複数日の指示は入らない', () {
    expect(diary(multi: false), isNot(contains('どの日も省かずに')));
  });

  group('ブログ風', () {
    String blog({required bool multi}) => DiaryStylePrompt.section(
      style: DiaryStyle.blog,
      customInstruction: '',
      isMultiDay: multi,
    );

    test('複数日のときは、期間の全体を書かせる指示が入る', () {
      final text = blog(multi: true);

      expect(text, contains('期間の全体を、最初から最後まで'));
      expect(text, contains('最後の日や、1日だけの話にしない'));
    });

    test('1日のときは、複数日の指示は入らない', () {
      expect(blog(multi: false), isNot(contains('期間の全体を')));
    });
  });

  group('時系列の記録と箇条書き', () {
    String of(DiaryStyle style, {required bool multi}) =>
        DiaryStylePrompt.section(
          style: style,
          customInstruction: '',
          isMultiDay: multi,
        );

    for (final style in [DiaryStyle.record, DiaryStyle.bullets]) {
      test('$style: 複数日のときは、期間の全体を日ごとに書かせる指示が入る', () {
        final text = of(style, multi: true);

        expect(text, contains('最初の日から最後の日まで'));
        expect(text, contains('最後の日だけの記録にしない'));
        expect(text, contains('1日あたり1〜3行'));
      });

      test('$style: 1日のときは、複数日の注意は入らない', () {
        expect(of(style, multi: false), isNot(contains('最初の日から最後の日まで')));
      });
    }
  });
}
