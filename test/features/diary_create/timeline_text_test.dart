import 'package:auto_diary_ai/features/diary_create/domain/services/timeline_text.dart';
import 'package:auto_diary_ai/features/location/domain/entities/timeline_item.dart';
import 'package:flutter_test/flutter_test.dart';

Stay stay({String? placeName, String? estimated, bool edited = false}) => Stay(
  start: DateTime(2026, 1, 1, 9),
  end: DateTime(2026, 1, 1, 10),
  latitude: 35.68123,
  longitude: 139.76712,
  placeName: placeName,
  estimatedPlaceName: estimated,
  isPlaceNameEdited: edited,
);

void main() {
  multiDayTests();

  group('住所は、送ると決めた滞在だけ送る', () {
    test('名前を書き換えた(登録した)場所は、その名前だけを送る', () {
      final s = stay(placeName: '自宅', edited: true);

      expect(TimelineText.format([s]), '2026年1月1日\n09:00〜10:00 滞在: 自宅');
      expect(
        TimelineText.format([s], addressStays: {s}),
        '2026年1月1日\n09:00〜10:00 滞在: 自宅',
      );
    });

    test('施設を推定した場所は、初めは施設名だけ。送ると決めたら、住所も付ける', () {
      final s = stay(placeName: '東京都港区芝公園', estimated: '東京タワー');

      expect(TimelineText.format([s]), '2026年1月1日\n09:00〜10:00 滞在: 東京タワー(推定)');
      expect(
        TimelineText.format([s], addressStays: {s}),
        '2026年1月1日\n09:00〜10:00 滞在: 東京タワー(推定。住所: 東京都港区芝公園)',
      );
    });

    test('住所だけが分かる場所は、初めは場所を伝えない。送ると決めたら、住所を送る', () {
      final s = stay(placeName: '東京都港区芝公園');

      expect(TimelineText.format([s]), '2026年1月1日\n09:00〜10:00 滞在: 場所の情報なし');
      expect(
        TimelineText.format([s], addressStays: {s}),
        '2026年1月1日\n09:00〜10:00 滞在: 東京都港区芝公園',
      );
    });

    test('住所も施設も分からない場所は、座標を、初めは送らない', () {
      final s = stay();

      final text = TimelineText.format([s]);
      expect(text, '2026年1月1日\n09:00〜10:00 滞在: 場所の情報なし');
      expect(text, isNot(contains('緯度')));
      expect(
        TimelineText.format([s], addressStays: {s}),
        '2026年1月1日\n09:00〜10:00 滞在: 緯度35.6812 経度139.7671付近',
      );
    });

    test('送ると決めていない滞在には、住所が一切入らない', () {
      final chosen = stay(placeName: '東京都港区芝公園');
      final other = stay(placeName: '東京都千代田区丸の内');

      final text = TimelineText.format([chosen, other], addressStays: {chosen});
      expect(text, contains('東京都港区芝公園'));
      expect(text, isNot(contains('丸の内')));
    });
  });
}

// 日付の見出し(複数日を選んだとき、どの日の履歴か分かるようにする)
void multiDayTests() {
  Stay stayAt(DateTime start, DateTime end, String name) => Stay(
    start: start,
    end: end,
    latitude: 35,
    longitude: 139,
    placeName: name,
    isPlaceNameEdited: true,
  );

  group('日付の見出し', () {
    test('1日分でも、日付の見出しが付く', () {
      final s = stayAt(DateTime(2026, 1, 1, 9), DateTime(2026, 1, 1, 10), '自宅');

      expect(TimelineText.format([s]).split('\n').first, '2026年1月1日');
    });

    test('日が変わるごとに、見出しが付き、日付の順に並ぶ', () {
      final items = [
        stayAt(DateTime(2026, 1, 1, 9), DateTime(2026, 1, 1, 10), '自宅'),
        stayAt(DateTime(2026, 1, 1, 11), DateTime(2026, 1, 1, 12), '神社'),
        stayAt(DateTime(2026, 1, 2, 9), DateTime(2026, 1, 2, 10), 'カフェ'),
        stayAt(DateTime(2026, 1, 3, 9), DateTime(2026, 1, 3, 10), '公園'),
      ];

      expect(TimelineText.format(items).split('\n'), [
        '2026年1月1日',
        '09:00〜10:00 滞在: 自宅',
        '11:00〜12:00 滞在: 神社',
        '2026年1月2日',
        '09:00〜10:00 滞在: カフェ',
        '2026年1月3日',
        '09:00〜10:00 滞在: 公園',
      ]);
    });

    test('同じ日の履歴には、見出しを重ねない', () {
      final items = [
        stayAt(DateTime(2026, 1, 1, 9), DateTime(2026, 1, 1, 10), 'A'),
        stayAt(DateTime(2026, 1, 1, 11), DateTime(2026, 1, 1, 12), 'B'),
      ];

      expect('年'.allMatches(TimelineText.format(items)).length, 1);
    });
  });
}
