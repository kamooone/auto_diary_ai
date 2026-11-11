import 'package:flutter/material.dart';

/// 最初の許可(位置情報・身体活動・通知)を求める前に、何のための許可かを説明する
///
/// OSの許可のポップアップは、文言を変えられない。説明がないと許可されにくいため、
/// 求める順番(位置情報 → 身体活動 → 通知)で、先にここで説明する。
Future<void> showPermissionIntroDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text("最初に、3つの許可をお願いします"),
        content: const SingleChildScrollView(
          child: Text(
            "行動を自動で記録して、日記の材料にします。そのために、次の許可を順番にお願いします。\n\n"
            "■ 位置情報\n"
            "行動した場所と時間を記録します。次の画面では「アプリの使用時のみ」"
            "(iPhoneでは「Appの使用中は許可」)を選んでください。\n\n"
            "■ 身体活動\n"
            "徒歩・自転車・電車などの移動手段を記録します。歩数を数えるものではありません。\n\n"
            "■ 通知\n"
            "お問い合わせの返信などのお知らせに使います。\n\n"
            "記録はスマホの中に保存されます。AIに送るのは、日記を作るときに選んだ分だけです。"
            "許可しなくてもアプリは使えます。あとからスマホの設定で変えられます。",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("次へ"),
          ),
        ],
      ),
    ),
  );
}
