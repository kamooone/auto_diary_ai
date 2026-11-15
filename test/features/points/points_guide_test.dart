import 'package:auto_diary_ai/features/points/presentation/ui/points_guide_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ポイントとトークンの使い方を、最後の手順までスクロールして読める', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PointsGuidePage()));

    expect(find.text('Webで、アカウントを作る'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(find.text('トークンが使えるようになります'), findsOneWidget);
  });
}
