import 'package:flutter/material.dart';
import 'package:auto_diary_ai/common/constants/app_sizes.dart';

/// ホーム画面の外枠(ヘッダーに、アプリのアイコンと、名前を出す)
class HomeScaffold extends StatelessWidget {
  final Widget body;
  final String title;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;

  const HomeScaffold({
    super.key,
    required this.body,
    required this.title,
    this.actions,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSizes.space16,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radius12 - 2),
              child: Image.asset(
                'assets/icon/app_icon_small.png',
                width: 36,
                height: 36,
                // 画像を読めなくても、画面は出す
                errorBuilder: (_, __, ___) =>
                    const SizedBox(width: 36, height: 36),
              ),
            ),
            const SizedBox(width: AppSizes.space12),
            Flexible(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
        actions: actions,
      ),
      body: SafeArea(child: body),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
