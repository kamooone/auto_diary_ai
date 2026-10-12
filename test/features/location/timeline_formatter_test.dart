import 'package:auto_diary_ai/features/location/domain/entities/timeline_item.dart';
import 'package:auto_diary_ai/features/location/presentation/formatters/timeline_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

Stay stay({
  String? placeName = '東京都千代田区丸の内',
  String? estimatedPlaceName,
  bool isPlaceNameEdited = false,
  bool isPlaceSearchFailed = false,
}) {
  return Stay(
    start: DateTime(2026, 1, 1, 9, 0),
    end: DateTime(2026, 1, 1, 10, 0),
    latitude: 35.0,
    longitude: 139.0,
    placeName: placeName,
    estimatedPlaceName: estimatedPlaceName,
    isPlaceNameEdited: isPlaceNameEdited,
    isPlaceSearchFailed: isPlaceSearchFailed,
  );
}

void main() {
  test('訪れた場所を取得できず地名のまま表示する場合は、その旨を添える', () {
    expect(
      TimelineFormatter.stayTitle(stay(), showNotFound: true),
      '東京都千代田区丸の内（取得できませんでした）',
    );
  });

  test('通信に失敗して取得できなかった場合は、訪れた場所がなかった場合と別の文言にする', () {
    expect(
      TimelineFormatter.stayTitle(
        stay(isPlaceSearchFailed: true),
        showNotFound: true,
      ),
      '東京都千代田区丸の内（通信に失敗しました）',
    );
  });

  test('通信に失敗していても、ユーザーが入力した場所名には何も添えない', () {
    expect(
      TimelineFormatter.stayTitle(
        stay(
          placeName: '自宅',
          isPlaceNameEdited: true,
          isPlaceSearchFailed: true,
        ),
        showNotFound: true,
      ),
      '自宅',
    );
  });

  test('取得の途中など、その旨を添えない指定の場合は地名だけを表示する', () {
    expect(TimelineFormatter.stayTitle(stay()), '東京都千代田区丸の内');
  });

  test('訪れた場所を取得できた場合は、推定として表示する', () {
    expect(
      TimelineFormatter.stayTitle(
        stay(estimatedPlaceName: 'カフェA'),
        showNotFound: true,
      ),
      'カフェA（推定）',
    );
  });

  test('ユーザーが入力した場所名には、その旨を添えない', () {
    expect(
      TimelineFormatter.stayTitle(
        stay(placeName: '自宅', isPlaceNameEdited: true),
        showNotFound: true,
      ),
      '自宅',
    );
  });

  test('地名もない場合は、場所名を取得できなかったことだけを表示する', () {
    expect(
      TimelineFormatter.stayTitle(stay(placeName: null), showNotFound: true),
      '場所名を取得できませんでした',
    );
  });
}
