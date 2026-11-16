import 'package:auto_diary_ai/common/widgets/app_bottom_sheet.dart';
import 'package:auto_diary_ai/common/widgets/app_search_field.dart';
import 'package:auto_diary_ai/common/widgets/app_tag.dart';
import 'package:auto_diary_ai/common/widgets/confirm_dialog.dart';
import 'package:auto_diary_ai/common/widgets/filter_chip_field.dart';
import 'package:auto_diary_ai/common/widgets/icon_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget wrap(Widget child, {double textScale = 1}) => MaterialApp(
  builder: (context, c) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: c!,
  ),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('FilterChipField', () {
    testWidgets('押すとメニューが開き、選ぶと通知される(「すべて」への解除も)', (tester) async {
      int? changed = 0;
      await tester.pumpWidget(
        wrap(
          StatefulBuilder(
            builder: (context, setState) => FilterChipField<int>(
              label: '年',
              value: changed,
              options: const [(null, 'すべて'), (2026, '2026年')],
              onChanged: (v) => setState(() => changed = v),
            ),
          ),
        ),
      );

      await tester.tap(find.text('年'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2026年').last);
      await tester.pumpAndSettle();
      expect(changed, 2026);

      await tester.tap(find.text('2026年'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('すべて').last);
      await tester.pumpAndSettle();
      expect(changed, isNull);
    });

    testWidgets('選べないときは、押しても開かない', (tester) async {
      await tester.pumpWidget(
        wrap(
          const FilterChipField<int>(
            label: '月',
            value: null,
            options: [(null, 'すべて'), (1, '1月')],
            onChanged: null,
          ),
        ),
      );

      await tester.tap(find.text('月'));
      await tester.pumpAndSettle();
      expect(find.text('1月'), findsNothing);
    });
  });

  testWidgets('検索欄に文字を入れると通知される', (tester) async {
    String? text;
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 300,
          child: AppSearchField(hintText: '投稿を検索', onChanged: (v) => text = v),
        ),
      ),
    );

    expect(find.text('投稿を検索'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '海');
    expect(text, '海');
  });

  testWidgets('札とアイコンのボタン', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppTag('リプライ'),
            IconActionButton(
              icon: Icons.delete_outline,
              label: '削除',
              onPressed: () => tapped = true,
            ),
          ],
        ),
      ),
    );

    expect(find.text('リプライ'), findsOneWidget);
    await tester.tap(find.byTooltip('削除'));
    expect(tapped, isTrue);
  });

  group('ConfirmDialog', () {
    Future<void> open(WidgetTester tester, {double textScale = 1}) async {
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showConfirmDialog(
                context,
                icon: Icons.lightbulb_outline,
                title: '使い方の説明を\nもう一度見ますか？',
                message: 'ホームに戻ると、説明が始まります。',
                confirmLabel: '見る',
              ),
              child: const Text('開く'),
            ),
          ),
          textScale: textScale,
        ),
      );
      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();
    }

    testWidgets('右のボタンで true、左のボタンで false を返す', (tester) async {
      bool? result;
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await showConfirmDialog(
                context,
                icon: Icons.lightbulb_outline,
                title: 'タイトル',
                message: '説明',
                confirmLabel: '見る',
              ),
              child: const Text('開く'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('見る'));
      await tester.pumpAndSettle();
      expect(result, isTrue);

      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });

    testWidgets('文字を大きくしても、あふれない', (tester) async {
      await open(tester, textScale: 2);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('下から出るシートは、長い中身をスクロールできる', (tester) async {
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showAppBottomSheet<void>(
              context,
              title: 'タイトル',
              builder: (context) => SingleChildScrollView(
                child: Column(
                  children: [
                    for (var i = 0; i < 60; i++) Text('行$i'),
                    const Text('最後'),
                  ],
                ),
              ),
            ),
            child: const Text('開く'),
          ),
        ),
        textScale: 1.6,
      ),
    );

    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();
    expect(find.text('タイトル'), findsOneWidget);

    await tester.dragUntilVisible(
      find.text('最後'),
      find.byType(SingleChildScrollView).last,
      const Offset(0, -300),
    );
    expect(find.text('最後'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
