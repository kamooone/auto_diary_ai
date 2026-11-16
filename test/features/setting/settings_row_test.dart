import 'package:auto_diary_ai/features/setting/presentation/ui/widgets/settings_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('項目名と説明が出て、押せる行には矢印が出る', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      wrap(
        SettingsRow(
          icon: Icons.mail_outline,
          title: 'お問い合わせ',
          subtitle: '不具合のご報告',
          onTap: () => tapped++,
        ),
      ),
    );

    expect(find.text('お問い合わせ'), findsOneWidget);
    expect(find.text('不具合のご報告'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);

    await tester.tap(find.text('お問い合わせ'));
    expect(tapped, 1);
  });

  testWidgets('右に別のものを渡すと、矢印の代わりにそれが出る', (tester) async {
    await tester.pumpWidget(
      wrap(
        SettingsRow(
          icon: Icons.timeline,
          title: '行動履歴を記録する',
          trailing: Switch(value: true, onChanged: (_) {}),
          onTap: () {},
        ),
      ),
    );

    expect(find.byType(Switch), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  testWidgets('説明の下のボタンを押せる', (tester) async {
    var pressed = false;
    await tester.pumpWidget(
      wrap(
        SettingsRow(
          icon: Icons.widgets_outlined,
          title: 'ホーム画面に表示',
          extra: SettingsPillButton(
            label: '非表示にする',
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('非表示にする'));
    expect(pressed, isTrue);
  });
}
