import 'dart:async';

/// [items]を最大[concurrency]件ずつ並行して処理する
/// 戻り値は[items]と同じ順番
Future<List<R>> parallelMap<T, R>(
  List<T> items,
  Future<R> Function(T item) action, {
  int concurrency = 4,
}) async {
  final results = List<R?>.filled(items.length, null);
  var next = 0;

  Future<void> worker() async {
    while (next < items.length) {
      final index = next++;
      results[index] = await action(items[index]);
    }
  }

  await Future.wait([
    for (var i = 0; i < concurrency && i < items.length; i++) worker(),
  ]);

  return [for (final result in results) result as R];
}
