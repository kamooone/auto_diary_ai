import 'package:auto_diary_ai/features/x_archive/presentation/ui/x_archive_import_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('アーカイブを取り込む画面の右上から、取り込み方を開ける', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: XArchiveImportPage())),
    );

    await tester.tap(find.byTooltip('アーカイブの取り込み方'));
    await tester.pumpAndSettle();

    expect(find.text('アーカイブの取り込み方'), findsOneWidget);
    expect(find.text('Xで、アーカイブをリクエストする'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(find.text('取り込む年を選ぶ'), findsOneWidget);
  });
}
