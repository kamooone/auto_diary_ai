import 'package:auto_diary_ai/features/share/application/providers/share_providers.dart';
import 'package:auto_diary_ai/features/share/domain/entities/shared_post.dart';
import 'package:auto_diary_ai/features/share/presentation/ui/shared_post_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Xの投稿の画面の右上から、共有の流れを開ける', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allSharedPostsProvider.overrideWith((ref) async => <SharedPost>[]),
        ],
        child: const MaterialApp(home: SharedPostListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Xから共有する方法'));
    await tester.pumpAndSettle();

    expect(find.text('Xから共有する方法'), findsOneWidget);
    expect(find.text('Xのアプリで、保存したい投稿を開く'), findsOneWidget);

    // 下までスクロールして、最後の手順も見られる
    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(find.text('OKを押して保存する'), findsOneWidget);
  });
}
