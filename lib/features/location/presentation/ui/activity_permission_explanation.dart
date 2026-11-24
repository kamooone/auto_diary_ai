import 'package:flutter/material.dart';

/// 身体活動の許可を、OSに尋ねてもらう前の、アプリの説明
///
/// OSの許可のダイアログは、文面をアプリから変えられず、「身体活動データへのアクセスを…」としか出ない。
/// 何のために使うのかが伝わるよう、その前に、アプリの説明を出す。
///
/// 「次へ」を押したら true(このあと、OSのダイアログを出す)、「あとで」なら false
Future<bool> showActivityPermissionExplanation(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      scrollable: true,
      title: const Text("身体活動の許可について"),
      content: const Text(
        "行動履歴に、「歩いている」「自転車に乗っている」「乗り物に乗っている」など、"
        "移動の手段を自動で記録するために、端末の「身体活動」の情報を使います。\n\n"
        "このあとに表示される確認で、「許可」を選んでください。\n\n"
        "許可しなくても、行動履歴は使えます。その場合、移動の手段は、移動の速さからの目安になります。",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("あとで"),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text("次へ"),
        ),
      ],
    ),
  );

  return result == true;
}
