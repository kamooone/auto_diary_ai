import 'package:auto_diary_ai/features/x_archive/domain/entities/x_archive_post_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('何も指定しなければ、絞り込まない', () {
    const f = XArchivePostFilter.none;
    expect(f.isNone, isTrue);
    expect(f.from, isNull);
    expect(f.to, isNull);
  });

  test('年を選ぶと、日本時間の年の始まりから次の年の始まりまで(UTCで表す)', () {
    const f = XArchivePostFilter(year: 2025);
    expect(f.from, DateTime.utc(2024, 12, 31, 15));
    expect(f.to, DateTime.utc(2025, 12, 31, 15));
  });

  test('月を選ぶと、その月だけ。12月は翌年の1月までになる', () {
    const f = XArchivePostFilter(year: 2025, month: 12);
    expect(f.from, DateTime.utc(2025, 11, 30, 15));
    expect(f.to, DateTime.utc(2025, 12, 31, 15));
  });

  test('日を選ぶと、その日だけ(月末も正しく次の日になる)', () {
    const f = XArchivePostFilter(year: 2025, month: 2, day: 28);
    expect(f.from, DateTime.utc(2025, 2, 27, 15));
    expect(f.to, DateTime.utc(2025, 2, 28, 15));
  });

  test('年を変えると月と日が、月を変えると日が解除される。検索語は残る', () {
    const f = XArchivePostFilter(year: 2025, month: 3, day: 4, query: '犬');
    expect(f.withYear(2024).month, isNull);
    expect(f.withYear(2024).query, '犬');
    expect(f.withMonth(5).day, isNull);
    expect(f.withMonth(5).year, 2025);
    expect(f.withDay(9).day, 9);
  });

  test('検索語は空白(全角も)で区切り、小文字にする', () {
    const f = XArchivePostFilter(query: ' Hello　World  ');
    expect(f.words, ['hello', 'world']);
    expect(f.isNone, isFalse);
  });

  test('空白だけの検索語は、絞り込みなし', () {
    expect(const XArchivePostFilter(query: '  　').isNone, isTrue);
  });

  test('月の日数(うるう年を含む)', () {
    expect(XArchivePostFilter.daysInMonth(2024, 2), 29);
    expect(XArchivePostFilter.daysInMonth(2025, 2), 28);
    expect(XArchivePostFilter.daysInMonth(2025, 12), 31);
  });
}
