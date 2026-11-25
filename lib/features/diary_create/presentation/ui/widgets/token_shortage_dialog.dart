import 'package:flutter/material.dart';

/// トークンが足りないときの、ユーザーの選択(足りないときは、AIに送れない)
enum TokenShortageChoice { cancel, openPoints }

/// 日記を書いてもらう前に、今月の残りでは足りない見込みであることを知らせる。
/// 見込みが残りを超えるときは、送らせない。来月1日に毎月の枠が戻るまで待つか、
/// ゲームでポイントを貯めてトークンに交換するよう伝える
Future<TokenShortageChoice> showTokenShortageDialog(
  BuildContext context, {
  required int estimated,
  required int remaining,
  required int photoTokens,
}) async {
  final choice = await showDialog<TokenShortageChoice>(
    context: context,
    builder: (context) => AlertDialog(
      scrollable: true,
      title: const Text("トークンが足りません"),
      content: Text(
        "この日記に必要なトークンは、約${formatTokens(estimated)}の見込みです"
        "(目安です)。今月の残りは、${formatTokens(remaining)}です。\n\n"
        "写真を減らしたり、期間を短くしたりすると、必要な量が減ります。"
        "写真は1枚で約${formatTokens(photoTokens)}トークンです。\n\n"
        "毎月の無料の枠は、来月の1日に戻ります。それまで待つか、"
        "ゲームでポイントを貯めて、トークンに交換してください。",
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(TokenShortageChoice.cancel),
          child: const Text("やめる"),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(TokenShortageChoice.openPoints),
          child: const Text("ポイント・トークンを見る"),
        ),
      ],
    ),
  );

  return choice ?? TokenShortageChoice.cancel;
}

/// 3桁ごとにカンマで区切る
String formatTokens(int value) {
  return value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
}
