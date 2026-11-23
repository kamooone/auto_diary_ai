import 'package:auto_diary_ai/features/privacy/presentation/ui/privacy_policy_page.dart';
import 'package:auto_diary_ai/features/privacy/presentation/ui/terms_of_use_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('同梱の利用規約を、最後まで読める', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TermsOfUsePage()));
    await tester.pumpAndSettle();

    expect(find.text('利用規約'), findsWidgets);
    expect(find.text('1. 本アプリについて'), findsOneWidget);

    await tester.dragUntilVisible(
      find.text('12. お問い合わせ'),
      find.byType(ListView),
      const Offset(0, -400),
    );
    expect(find.text('12. お問い合わせ'), findsOneWidget);
  });

  testWidgets('利用規約に、ポイントの扱いの注意が書かれている', (tester) async {
    // 前のテストが読み込んだ結果を、使い回さないよう、毎回読み直す
    await tester.pumpWidget(
      MaterialApp(
        home: TermsOfUsePage(
          loader: () => rootBundle.loadString(
            TermsOfUsePage.assetPath,
            cache: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('4. ポイントとトークンについて'),
      find.byType(ListView),
      const Offset(0, -400),
    );
    expect(
      find.textContaining('現金や、ほかの商品に換えることはできません', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('制定日と最終改定日の両方を、小さく出す', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PrivacyPolicyPage(
          title: '題',
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
