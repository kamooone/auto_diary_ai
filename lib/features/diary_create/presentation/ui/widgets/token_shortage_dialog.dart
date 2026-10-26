import 'package:flutter/material.dart';
import '../../../domain/services/token_estimator.dart';

/// トークンが足りない見込みのときの、ユーザーの選択
enum TokenShortageChoice { cancel, openPoints, sendAnyway }

/// 日記を書いてもらう前に、今月の残りでは足りない見込みであることを知らせる
Future<TokenShortageChoice> showTokenShortageDialog(
  BuildContext context, {
  required int estimated,
  required int remaining,
}) async {
  final choice = await showDialog<TokenShortageChoice>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("トークンが足りない見込みです"),
      content: Text(
        "この日記に必要なトークンは、約${formatTokens(estimated)}の見込みです"
        "(目安です)。今月の残りは、${formatTokens(remaining)}です。\n\n"
        "写真を減らしたり、期間を短くしたりすると、必要な量が減ります。"
        "写真は1枚で約${formatTokens(TokenEstimator.tokensPerPhoto)}トークンです。\n\n"
        "足りない場合は、AIが日記を書いたあとに、残りが足りなくなることがあります。",
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
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(TokenShortageChoice.sendAnyway),
          child: const Text("それでも送る"),
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
