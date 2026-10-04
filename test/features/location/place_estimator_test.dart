import 'package:auto_diary_ai/features/location/domain/entities/place_candidate.dart';
import 'package:auto_diary_ai/features/location/domain/services/place_estimator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final estimator = PlaceEstimator();

  test('候補がなければ推定しない', () {
    expect(estimator.estimate([]), isNull);
  });

  test('最も近い施設を訪れた場所とみなす', () {
    final place = estimator.estimate(const [
      PlaceCandidate(name: 'カフェA', distanceMeters: 12),
      PlaceCandidate(name: 'コンビニB', distanceMeters: 40),
    ]);

    expect(place?.name, 'カフェA');
  });

  test('最も近い施設でも50mより離れていれば推定しない', () {
    final place = estimator.estimate(const [
      PlaceCandidate(name: 'カフェA', distanceMeters: 60),
    ]);

    expect(place, isNull);
  });
}
