import 'package:flutter/material.dart';
import 'app_log.dart';

/// 動作確認用に、ログを画面に重ねて表示する
class AppLogPanel extends StatelessWidget {
  final VoidCallback onClose;

  const AppLogPanel({super.key, required this.onClose});

  // 表示する行数
  static const _visibleLines = 14;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 240),
      padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'ログ',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              TextButton(
                onPressed: AppLog.clear,
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('消去', style: TextStyle(fontSize: 12)),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, color: Colors.white, size: 16),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          Flexible(
            child: ValueListenableBuilder<List<String>>(
              valueListenable: AppLog.entries,
              builder: (context, entries, _) {
                final lines = entries.length > _visibleLines
                    ? entries.sublist(entries.length - _visibleLines)
                    : entries;

                return SingleChildScrollView(
                  reverse: true,
                  child: SelectableText(
                    lines.isEmpty ? '(まだログはありません)' : lines.join('\n'),
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 10,
                      height: 1.3,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
