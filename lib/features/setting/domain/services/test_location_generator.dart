import 'dart:math' as math;

/// テスト用の行動履歴で、位置の記録を作る
///
/// 動作確認が目的なので、全日ではなく、[_sampleEveryDays]日おきの日と、旅行の日、
/// 特別な日だけ作る(約60日分、約2,000件)。
/// 滞在する場所は、すべて「登録した場所」として先に渡すので、タイムラインを作るときに、
/// 地名や施設をネットで調べない。名前は[namePrefix]で始まる(削除のときの目印)。
/// 位置の記録には、目印を付けられないので、保存したIDを別に控えて、削除に使う
class TestLocationGenerator {
  const TestLocationGenerator._();

  static const namePrefix = "【テスト】";

  /// 全日のうち、この日数おきの日を作る
  static const _sampleEveryDays = 5;

  /// 旅行の日と、特別な日(日記と同じ日)
  static const _extraDays = {
    "1/1", "3/28", "9/13", "10/11", // 初詣・花見・ライブ・レース
    "5/3", "5/4", "5/5", // 京都
    "8/9", "8/10", "8/11", // 海辺の町
  };

  /// [first]から[last]まで
  static TestLocationData generate({
    required DateTime first,
    required DateTime last,
  }) {
    final points = <TestLocationPoint>[];
    var index = 0;

    for (
      var day = DateTime(first.year, first.month, first.day);
      !day.isAfter(last);
      day = DateTime(day.year, day.month, day.day + 1), index++
    ) {
      final isExtra = _extraDays.contains("${day.month}/${day.day}");
      if (!isExtra && index % _sampleEveryDays != 0) continue;

      points.addAll(_Day(day, index).build());
    }

    return TestLocationData(
      places: [
        for (final place in _places.values)
          TestLocationPlace(
            name: "$namePrefix${place.name}",
            latitude: place.latitude,
            longitude: place.longitude,
          ),
      ],
      points: points,
    );
  }

  // 場所(日常は東京の近く、旅行は京都と海辺の町)
  static const _places = <String, TestLocationPlace>{
    "home": TestLocationPlace(name: "自宅", latitude: 35.7295, longitude: 139.7109),
    "office": TestLocationPlace(name: "職場", latitude: 35.6812, longitude: 139.7671),
    "cafe": TestLocationPlace(name: "カフェ「ことり」", latitude: 35.7011, longitude: 139.7456),
    "shrine": TestLocationPlace(name: "近所の神社", latitude: 35.7160, longitude: 139.7000),
    "park": TestLocationPlace(name: "近所の公園", latitude: 35.7330, longitude: 139.7200),
    "library": TestLocationPlace(name: "市立図書館", latitude: 35.7205, longitude: 139.7300),
    "museum": TestLocationPlace(name: "美術館", latitude: 35.7188, longitude: 139.7745),
    "bookstore": TestLocationPlace(name: "大きな書店", latitude: 35.6900, longitude: 139.7000),
    "supermarket": TestLocationPlace(name: "スーパー", latitude: 35.7270, longitude: 139.7080),
    "gym": TestLocationPlace(name: "ジム", latitude: 35.7120, longitude: 139.7140),
    "livehouse": TestLocationPlace(name: "ライブハウス", latitude: 35.6620, longitude: 139.7010),
    "raceCourse": TestLocationPlace(name: "レースの会場", latitude: 35.6300, longitude: 139.7500),
    // 京都
    "kyotoStation": TestLocationPlace(name: "京都駅", latitude: 34.9858, longitude: 135.7588),
    "kyotoInn": TestLocationPlace(name: "京都の宿", latitude: 35.0000, longitude: 135.7600),
    "fushimi": TestLocationPlace(name: "伏見稲荷大社", latitude: 34.9671, longitude: 135.7727),
    "kiyomizu": TestLocationPlace(name: "清水寺", latitude: 34.9949, longitude: 135.7850),
    "nishiki": TestLocationPlace(name: "錦市場", latitude: 35.0050, longitude: 135.7650),
    "arashiyama": TestLocationPlace(name: "嵐山の竹林", latitude: 35.0170, longitude: 135.6710),
    "ginkaku": TestLocationPlace(name: "銀閣寺", latitude: 35.0270, longitude: 135.7980),
    // 海辺の町
    "seaInn": TestLocationPlace(name: "海辺の町の宿", latitude: 35.1000, longitude: 139.0750),
    "beach": TestLocationPlace(name: "海水浴場", latitude: 35.0960, longitude: 139.0790),
    "fishMarket": TestLocationPlace(name: "漁港の市場", latitude: 35.1040, longitude: 139.0800),
    "lighthouse": TestLocationPlace(name: "岬の灯台", latitude: 35.1130, longitude: 139.0900),
  };

  // 休日の外出先(順番に回る)
  static const _outings = ["cafe", "park", "library", "museum", "bookstore", "shrine"];
}

/// テスト用の位置の記録と、滞在する場所
class TestLocationData {
  final List<TestLocationPlace> places;
  final List<TestLocationPoint> points;

  const TestLocationData({required this.places, required this.points});
}

/// 滞在する場所(登録した場所にする)
class TestLocationPlace {
  final String name;
  final double latitude;
  final double longitude;

  const TestLocationPlace({
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}

/// 位置の記録1件
class TestLocationPoint {
  final double latitude;
  final double longitude;
  final DateTime time;

  const TestLocationPoint({
    required this.latitude,
    required this.longitude,
    required this.time,
  });
}

/// 1日分の位置の記録を、「滞在」と「移動」を順に足して作る
class _Day {
  _Day(this.day, this.index) : _time = day, _place = TestLocationGenerator._places["home"]!;

  final DateTime day;
  final int index;
  final _points = <TestLocationPoint>[];

  DateTime _time;
  TestLocationPlace _place;
  var _count = 0;

  static TestLocationPlace _of(String key) => TestLocationGenerator._places[key]!;

  List<TestLocationPoint> build() {
    final key = "${day.month}/${day.day}";

    switch (key) {
      case "5/3":
        _stay(until: 7, minute: 0);
        _travel("kyotoStation", minutes: 130, step: 10);
        _travelTo("fushimi", minutes: 15, until: 13, untilMinute: 30);
        _travelTo("kyotoInn", minutes: 40, until: 23, untilMinute: 59);
      case "5/4":
        _stay(until: 8, minute: 30, place: "kyotoInn");
        _travelTo("kiyomizu", minutes: 25, until: 11);
        _travelTo("nishiki", minutes: 15, until: 13, untilMinute: 30);
        _travelTo("arashiyama", minutes: 40, until: 16, untilMinute: 30);
        _travelTo("kyotoInn", minutes: 40, until: 23, untilMinute: 59);
      case "5/5":
        _stay(until: 9, minute: 0, place: "kyotoInn");
        _travelTo("ginkaku", minutes: 30, until: 12);
        _travelTo("kyotoStation", minutes: 25, until: 14, untilMinute: 30);
        _travel("home", minutes: 130, step: 10);
        _stay(until: 23, minute: 59);
      case "8/9":
        _stay(until: 7, minute: 30);
        _travel("seaInn", minutes: 120, step: 10);
        _travelTo("beach", minutes: 10, until: 16);
        _travelTo("seaInn", minutes: 10, until: 23, untilMinute: 59);
      case "8/10":
        _stay(until: 8, minute: 0, place: "seaInn");
        _travelTo("fishMarket", minutes: 10, until: 10);
        _travelTo("lighthouse", minutes: 20, until: 13);
        _travelTo("seaInn", minutes: 20, until: 23, untilMinute: 59);
      case "8/11":
        _stay(until: 9, minute: 0, place: "seaInn");
        _travelTo("beach", minutes: 10, until: 11);
        _travelTo("seaInn", minutes: 10, until: 13);
        _travel("home", minutes: 120, step: 10);
        _stay(until: 23, minute: 59);
      case "1/1":
        _stay(until: 9, minute: 0);
        _travelTo("shrine", minutes: 20, until: 10, untilMinute: 30);
        _travelTo("cafe", minutes: 15, until: 12);
        _travelTo("home", minutes: 25, until: 23, untilMinute: 59);
      case "3/28":
        _stay(until: 10, minute: 30);
        _travelTo("park", minutes: 20, until: 17);
        _travelTo("home", minutes: 20, until: 23, untilMinute: 59);
      case "9/13":
        _stay(until: 16, minute: 0);
        _travelTo("livehouse", minutes: 40, until: 21);
        _travelTo("home", minutes: 40, until: 23, untilMinute: 59);
      case "10/11":
        _stay(until: 6, minute: 30);
        _travelTo("raceCourse", minutes: 50, until: 11);
        _travelTo("home", minutes: 50, until: 23, untilMinute: 59);
      default:
        day.weekday <= 5 ? _weekday() : _weekend();
    }

    return _points;
  }

  // 平日: 自宅 → 職場 → (ジム・スーパー・まっすぐ) → 自宅
  void _weekday() {
    _stay(until: 7, minute: 30);
    _travelTo("office", minutes: 25, until: 18);

    switch (index % 3) {
      case 0:
        _travelTo("gym", minutes: 20, until: 19, untilMinute: 30);
        _travelTo("home", minutes: 15, until: 23, untilMinute: 59);
      case 1:
        _travelTo("supermarket", minutes: 20, until: 19);
        _travelTo("home", minutes: 10, until: 23, untilMinute: 59);
      default:
        _travelTo("home", minutes: 25, until: 23, untilMinute: 59);
    }
  }

  // 休日: 自宅 → 外出先(1〜2か所) → 自宅
  void _weekend() {
    final first = TestLocationGenerator._outings[index % TestLocationGenerator._outings.length];
    final second = TestLocationGenerator._outings[(index + 2) % TestLocationGenerator._outings.length];

    _stay(until: 9, minute: 30);
    _travelTo(first, minutes: 20, until: 12, untilMinute: 30);

    if (index % 2 == 0) {
      _travelTo(second, minutes: 15, until: 16);
    }

    _travelTo("home", minutes: 20, until: 23, untilMinute: 59);
  }

  // 今いる場所に、指定の時刻まで滞在する(位置の記録は、2時間おき)
  void _stay({required int until, required int minute, String? place}) {
    if (place != null) {
      _place = _of(place);
    }

    final end = DateTime(day.year, day.month, day.day, until, minute);
    _addStayPoints(end);
  }

  // 別の場所へ向かい(移動の記録を足す)、着いたら、指定の時刻まで滞在する
  void _travelTo(
    String place, {
    required int minutes,
    required int until,
    int untilMinute = 0,
  }) {
    _travel(place, minutes: minutes, step: 2);
    _addStayPoints(DateTime(day.year, day.month, day.day, until, untilMinute));
  }

  // 移動。[step]分おきに、2つの場所の間の位置を記録する
  void _travel(String place, {required int minutes, required int step}) {
    final to = _of(place);

    for (var elapsed = step; elapsed < minutes; elapsed += step) {
      final ratio = elapsed / minutes;

      _points.add(
        TestLocationPoint(
          latitude: _place.latitude + (to.latitude - _place.latitude) * ratio,
          longitude: _place.longitude + (to.longitude - _place.longitude) * ratio,
          time: _time.add(Duration(minutes: elapsed)),
        ),
      );
    }

    _time = _time.add(Duration(minutes: minutes));
    _place = to;
  }

  // 滞在の位置の記録。着いてから1分後、2時間おき、出発の1分前
  void _addStayPoints(DateTime end) {
    var at = _time.add(const Duration(minutes: 1));

    while (at.isBefore(end.subtract(const Duration(minutes: 1)))) {
      _addStayPoint(at);
      at = at.add(const Duration(hours: 2));
    }

    final last = end.subtract(const Duration(minutes: 1));
    if (last.isAfter(_time)) _addStayPoint(last);

    _time = end;
  }

  // 同じ場所でも、GPSの誤差のように、数mずつずらす
  void _addStayPoint(DateTime time) {
    final angle = _count * 2.4;
    final meters = 3.0 + (_count % 4) * 2;
    _count++;

    _points.add(
      TestLocationPoint(
        latitude: _place.latitude + meters * math.sin(angle) / 111000,
        longitude: _place.longitude + meters * math.cos(angle) / 91000,
        time: time,
      ),
    );
  }
}
