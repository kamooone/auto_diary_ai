import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_diary_ai/app.dart';

void main() {
  testWidgets('App starts without crashing', (WidgetTester tester) async {

    await tester.pumpWidget(
      ProviderScope(
        child: App(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(App), findsOneWidget);
  });
}