import 'package:auto_diary_ai/app/startup/permission_intro_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('3つの許可の説明を出し、「次へ」で閉じる(外側のタップでは閉じない)', (tester) async {
    var closed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              await showPermissionIntroDialog(context);
              closed = true;
            },
            child: const Text('開く'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();

    expect(find.textContaining('位置情報'), findsWidgets);
    expect(find.textContaining('身体活動'), findsWidgets);
    expect(find.textContaining('通知'), findsWidgets);

    await tester.tapAt(const Offset(2, 2));
    await tester.pumpAndSettle();
    expect(closed, isFalse);

    await tester.tap(find.text('次へ'));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
  });
}
