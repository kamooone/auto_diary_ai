import 'package:auto_diary_ai/features/location/presentation/ui/location_permission_explanation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<Future<bool> Function()> open(WidgetTester tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            context = c;
            return const Scaffold(body: SizedBox.expand());
          },
        ),
      ),
    );
    return () => showLocationPermissionExplanation(context);
  }

  testWidgets('バックグラウンドでの取得・使いみち・AIへの扱いを説明する', (tester) async {
    final show = await open(tester);
    show();
    await tester.pumpAndSettle();

    expect(find.text('位置情報の利用について'), findsOneWidget);
    expect(find.textContaining('バックグラウンドで位置情報を取得します'), findsOneWidget);
    expect(find.textContaining('端末の中に保存します'), findsOneWidget);
    expect(find.textContaining('AIに日記を書いてもらう」ときの材料'), findsOneWidget);
    expect(find.textContaining('選ばなければ、送りません'), findsOneWidget);
    expect(find.textContaining('いつでもオフにできます'), findsOneWidget);
  });

  testWidgets('「同意して続ける」を押すと true(このあと、OSの許可のダイアログを出す)', (tester) async {
    final show = await open(tester);
    final result = show();
    await tester.pumpAndSettle();

    await tester.tap(find.text('同意して続ける'));
    await tester.pumpAndSettle();

    expect(await result, isTrue);
  });

  testWidgets('「あとで」を押すと false(OSの許可のダイアログは出さない)', (tester) async {
    final show = await open(tester);
    final result = show();
    await tester.pumpAndSettle();

    await tester.tap(find.text('あとで'));
    await tester.pumpAndSettle();

    expect(await result, isFalse);
  });

  testWidgets('ダイアログの外を押しても、閉じない(説明を読まずに進めないようにする)', (tester) async {
    final show = await open(tester);
    show();
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(find.text('位置情報の利用について'), findsOneWidget);
  });
}
