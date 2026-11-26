import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auto_diary_ai/features/diary_create/presentation/ui/generate_flow.dart';

void main() {
  testWidgets('相談を始める前の確認に、続けるときの消費と、途中で足りなくなったときの案内が出る', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () =>
                  confirmBeforeConsult(context, ref, estimatedTokens: 8000),
              child: const Text('開く'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();

    expect(find.text('AIに構成を相談しますか？'), findsOneWidget);
    expect(
      find.textContaining('続けて相談するときは、日記の全文は送らないので、消費は少なくなりますが、'),
      findsOneWidget,
    );
    expect(
      find.textContaining('途中でトークンが足りなくなると、次の送信から使えなくなります。'),
      findsOneWidget,
    );
  });
}
