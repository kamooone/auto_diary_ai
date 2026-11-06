import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../../domain/services/generation_gauge.dart';

/// 日記を作っている間の表示(ダウンロードのようなゲージと、パーセント)
///
/// ゲージは、見積もった所要時間に合わせて進む目安で、正確な進み具合ではない。
/// 見積もった時間を過ぎたら、終わりの時間が分からない動きの棒にする(止まって見えないように)。
/// [isDone]がtrueになったら、100%まで一気に満たして、[onFinished]を呼ぶ。
class GenerationProgress extends StatefulWidget {
  const GenerationProgress({
    super.key,
    required this.expectedSeconds,
    this.isDone = false,
    this.onFinished,
  });

  /// 見積もった所要時間(秒)
  final int expectedSeconds;

  /// 作成が終わった(100%まで満たして、終わりを知らせる)
  final bool isDone;

  /// 100%まで満たし終えたとき
  final VoidCallback? onFinished;

  /// 100%まで満たす時間
  static const finishDuration = Duration(milliseconds: 400);

  @override
  State<GenerationProgress> createState() => _GenerationProgressState();
}

class _GenerationProgressState extends State<GenerationProgress>
    with SingleTickerProviderStateMixin {
  // 経過時間は、描画の時計(Ticker)で測る
  late final Ticker _ticker;
  Duration _elapsed = Duration.zero;

  // 作成が終わった時点の、経過時間とゲージの位置
  Duration? _finishedAt;
  double _finishedFrom = 0;
  var _notified = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    if (widget.isDone) _startFinish();
  }

  @override
  void didUpdateWidget(GenerationProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDone && _finishedAt == null) _startFinish();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _startFinish() {
    _finishedAt = _elapsed;
    // 終わりの時間が分からない動きになっていたときは、90%から満たす
    _finishedFrom = _isOver
        ? 0.9
        : GenerationGauge.fraction(_seconds, widget.expectedSeconds);
  }

  double get _seconds => _elapsed.inMilliseconds / 1000;

  bool get _isOver =>
      GenerationGauge.isOverExpected(_seconds, widget.expectedSeconds);

  void _onTick(Duration elapsed) {
    setState(() => _elapsed = elapsed);

    final finishedAt = _finishedAt;
    if (finishedAt != null &&
        !_notified &&
        elapsed - finishedAt >= GenerationProgress.finishDuration) {
      _notified = true;
      widget.onFinished?.call();
    }
  }

  // 満たしている間の、ゲージの位置(0〜1)
  double _finishingFraction() {
    final finishedAt = _finishedAt!;
    final t =
        ((_elapsed - finishedAt).inMilliseconds /
                GenerationProgress.finishDuration.inMilliseconds)
            .clamp(0.0, 1.0);

    return _finishedFrom + (1 - _finishedFrom) * Curves.easeOut.transform(t);
  }

  @override
  Widget build(BuildContext context) {
    final isFinishing = _finishedAt != null;

    // 見積もった時間を過ぎている間は、値を決めない(流れる棒)
    final isIndeterminate = !isFinishing && _isOver;

    final double? fraction = isFinishing
        ? _finishingFraction()
        : isIndeterminate
        ? null
        : GenerationGauge.fraction(_seconds, widget.expectedSeconds);

    final theme = Theme.of(context);

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
              fraction == null ? "処理中…" : "${(fraction * 100).floor()}%",
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              isIndeterminate
                  ? "AIが混み合っていると、時間がかかります。そのままお待ちください"
                  : "ゲージは目安です。写真や件数が多いと、時間がかかります",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
