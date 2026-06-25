import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('App starts without crashing', (tester) async {

    await tester.pumpWidget(
      const MaterialApp(
        home: Text("test"),
      ),
    );

    expect(find.text("test"), findsOneWidget);
  });
}