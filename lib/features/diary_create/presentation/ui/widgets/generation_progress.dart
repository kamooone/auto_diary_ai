import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../../domain/services/generation_gauge.dart';

/// 日記を作っている間の表示(ダウンロードのようなゲージと、経過時間)
///
/// ゲージは、見積もった所要時間に合わせて進む目安で、正確な進み具合ではない
class GenerationProgress extends StatefulWidget {
  const GenerationProgress({super.key, required this.expectedSeconds});

  /// 見積もった所要時間(秒)
  final int expectedSeconds;

  @override
  State<GenerationProgress> createState() => _GenerationProgressState();
}

class _GenerationProgressState extends State<GenerationProgress>
    with SingleTickerProviderStateMixin {
  // 経過時間は、描画の時計(Ticker)で測る
  late final Ticker _ticker;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) => setState(() => _elapsed = elapsed))
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = _elapsed.inMilliseconds / 1000;
    final fraction = GenerationGauge.fraction(elapsed, widget.expectedSeconds);
    final isOver = GenerationGauge.isOverExpected(elapsed, widget.expectedSeconds);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("日記を書いています…"),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: fraction, minHeight: 8),
            ),
            const SizedBox(height: 8),
            Text(
              "${elapsed.floor()}秒",
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              isOver ? "もう少しかかっています。そのままお待ちください" : "ゲージは目安です。写真や件数が多いと、時間がかかります",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
