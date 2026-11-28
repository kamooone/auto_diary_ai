import 'package:flutter/material.dart';

/// 位置情報の許可を、OSに尋ねてもらう前の、アプリの説明(目立つ開示)
///
/// バックグラウンドでも位置情報を取得すること、何のために使うのか、AIにどう扱うかを、
/// OSのダイアログの前に、利用者に伝える。同意するか、あとにするかを、選べる。
///
/// 「同意して続ける」を押したら true(このあと、OSのダイアログを出す)、「あとで」なら false
Future<bool> showLocationPermissionExplanation(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      scrollable: true,
      title: const Text("位置情報の利用について"),
      content: const Text(
        "「行動履歴を記録する」をオンにしている間、アプリを閉じていても、"
        "バックグラウンドで位置情報を取得します。\n\n"
        "取得した位置情報は、滞在した場所や移動の記録(行動履歴)を作るために使い、"
        "端末の中に保存します。行動履歴は、「AIに日記を書いてもらう」ときの材料として、"
        "使うことができます。\n\n"
        "行動履歴は、あなたが材料に選んで、AIに日記を書いてもらうときだけ、AIのサービスに送ります。"
        "選ばなければ、送りません。\n\n"
        "記録中は、通知に「位置情報を記録しています」と表示します。"
        "設定で、いつでもオフにできます。\n\n"
        "このあとに表示される確認で、位置情報を許可してください。",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("あとで"),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text("同意して続ける"),
        ),
      ],
    ),
  );

  return result == true;
}
