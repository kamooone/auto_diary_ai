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
}
