import 'package:auto_diary_ai/features/privacy/presentation/ui/privacy_policy_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('同梱のプライバシーポリシーを、最後まで読める', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PrivacyPolicyPage()));
    await tester.pumpAndSettle();

    expect(find.text('プライバシーポリシー'), findsWidgets);
    expect(find.text('1. 基本的な考え方'), findsOneWidget);

    await tester.dragUntilVisible(
      find.text('10. 変更について'),
      find.byType(ListView),
      const Offset(0, -400),
    );
    expect(find.text('10. 変更について'), findsOneWidget);
  });

  testWidgets('見出し・箇条書き・太字を、記号のまま出さない', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PrivacyPolicyPage(
          loader: () async => '# タイトル\n\n## 見出し\n\n- **太字**の項目\n\n本文',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('タイトル'), findsWidgets);
    expect(find.text('見出し'), findsOneWidget);
    expect(find.textContaining('**'), findsNothing);
    expect(find.textContaining('## '), findsNothing);
  });

  testWidgets('制定日と最終改定日の両方を、小さく出す', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PrivacyPolicyPage(
          loader: () async => '# 題\n\n制定日:2026年1月1日\n\n最終改定日:2026年2月2日\n\n本文',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('制定日:2026年1月1日'), findsOneWidget);
    expect(find.text('最終改定日:2026年2月2日'), findsOneWidget);
    // 線は、最後の日付の下に、1本だけ
    expect(find.byType(Divider), findsOneWidget);
  });
}
