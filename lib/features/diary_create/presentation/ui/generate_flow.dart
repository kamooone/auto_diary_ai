import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../ads/application/ads_provider.dart';
import '../../../ai/application/providers/ai_model_provider.dart';
import '../../domain/services/token_estimator.dart';
import '../../../plan/application/providers/plan_provider.dart';
import 'widgets/token_shortage_dialog.dart';

/// AIに日記を書いてもらう前の確認(トークン不足の案内 → 広告の許可 → 広告)
///
/// 続けてよければtrueを返す。やめた場合や、広告を最後まで見なかった場合はfalse
Future<bool> confirmBeforeGenerate(
  BuildContext context,
  WidgetRef ref, {
  required int estimatedTokens,
}) async {
  if (!await _passShortage(context, ref, estimatedTokens)) return false;
  if (!context.mounted) return false;

  // 広告を見る必要があることを伝えて、許可をもらう
  final agreed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("広告を見ますか？"),
      content: const Text("AIに日記を書いてもらうには、広告(動画)を最後まで見る必要があります。"),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("やめる"),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text("広告を見る"),
        ),
      ],
    ),
  );

  if (agreed != true || !context.mounted) return false;

  final allowed = await ref.read(adPolicyProvider).beforeGenerate();

  if (!context.mounted) return false;

  if (!allowed) {
    // 広告を最後まで見ないと、日記を書いてもらえない
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("広告を最後まで見ると、AIに日記を書いてもらえます")),
    );
    return false;
  }

  return true;
}

/// 今月の残りでは足りない見込みなら、先に知らせる
/// 続けてよければtrueを返す(やめた場合や、ポイント・トークンの画面へ進んだ場合はfalse)
Future<bool> _passShortage(
  BuildContext context,
  WidgetRef ref,
  int estimatedTokens,
) async {
  final usage = ref.read(usageProvider);
  if (usage == null || estimatedTokens <= usage.remainingTokens) return true;

  final choice = await showTokenShortageDialog(
    context,
    estimated: estimatedTokens,
    remaining: usage.remainingTokens,
    photoTokens: TokenEstimator.photoTokens(ref.read(aiModelProvider)),
  );
  if (!context.mounted) return false;

  if (choice == TokenShortageChoice.openPoints) {
    context.push(AppRoutes.points);
    return false;
  }

  return choice != TokenShortageChoice.cancel;
}

/// 書き方の相談を始める前の確認(日記の全文をAIに送るので、消費トークンの目安を知らせる)
///
/// 相談は広告を見ずに始められる。始めてよければtrueを返す
Future<bool> confirmBeforeConsult(
  BuildContext context,
  WidgetRef ref, {
  required int estimatedTokens,
}) async {
  if (!await _passShortage(context, ref, estimatedTokens)) return false;
  if (!context.mounted) return false;

  final usage = ref.read(usageProvider);
  final remaining = usage == null
      ? ""
      : "(今月の残り ${formatTokens(usage.remainingTokens)})";

  final agreed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("AIに構成を相談しますか？"),
      content: Text(
        "選んだ日記の内容をAIに送ります。消費トークンの目安は、"
        "約${formatTokens(estimatedTokens)}$remainingです。\n"
        "続けて相談するときは、日記の全文は送らないので、消費は少なくなります。",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("やめる"),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text("相談する"),
        ),
      ],
    ),
  );

  return agreed == true;
}
