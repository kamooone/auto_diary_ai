import 'package:auto_diary_ai/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('初期カウンターは0であること', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // カウンター表示の初期値をチェック
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);
  });

  testWidgets('ボタンを押すとカウンターが増えること', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // FloatingActionButton をタップ
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump(); // rebuild

    // カウンターが1になっているかチェック
    expect(find.text('1'), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });
}
