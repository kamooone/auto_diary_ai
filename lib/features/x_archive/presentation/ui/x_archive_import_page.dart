import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/x_archive_providers.dart';
import '../../application/services/x_archive_file_reader.dart';
import '../../domain/entities/x_archive_post.dart';
import '../../domain/services/x_archive_summary.dart';

/// Xのアーカイブ(tweets.js)を選んで、年ごとに取り込む画面
class XArchiveImportPage extends ConsumerStatefulWidget {
  const XArchiveImportPage({super.key});

  @override
  ConsumerState<XArchiveImportPage> createState() => _XArchiveImportPageState();
}

class _XArchiveImportPageState extends ConsumerState<XArchiveImportPage> {
  bool _reading = false;
  bool _importing = false;
  String? _error;

  List<XArchivePost>? _posts;
  Map<int, int> _yearCounts = {};
  final Set<int> _selectedYears = {};

  int _progress = 0;
  int _progressTotal = 0;
  String? _resultMessage;

  Future<void> _pick() async {
    setState(() {
      _error = null;
      _resultMessage = null;
    });

    final file = await FilePicker.pickFile();
    final path = file?.path;
    if (path == null) return;

    setState(() {
      _reading = true;
      _posts = null;
    });
    try {
      final posts = await readXArchiveFile(path);
      if (!mounted) return;
      final counts = countByYear(posts);
      setState(() {
        _posts = posts;
        _yearCounts = counts;
        _selectedYears
          ..clear()
          ..addAll(counts.keys);
      });
      if (posts.isEmpty) {
        setState(() => _error = '投稿が見つかりませんでした。tweets.js を選んでください。');
      }
    } on FormatException {
      if (!mounted) return;
      setState(() => _error = 'tweets.js の形ではありませんでした。ファイルを確かめてください。');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'ファイルを読めませんでした: $e');
    } finally {
      if (mounted) setState(() => _reading = false);
    }
  }

  Future<void> _import() async {
    final posts = _posts;
    if (posts == null || _selectedYears.isEmpty) return;
    final target = filterByYears(posts, _selectedYears);

    setState(() {
      _importing = true;
      _progress = 0;
      _progressTotal = target.length;
      _resultMessage = null;
      _error = null;
    });
    try {
      final result = await ref.read(xArchiveRepositoryProvider).import(
        target,
        onProgress: (done) {
          if (mounted) setState(() => _progress = done);
        },
      );
      if (!mounted) return;
      setState(() {
        _resultMessage = '${result.added}件を取り込みました'
            '(取り込み済みで飛ばした分: ${result.skipped}件)';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '取り込めませんでした: $e');
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _reading || _importing;
    final years = _yearCounts.keys.toList()..sort((a, b) => b.compareTo(a));
    final selectedCount = years
        .where(_selectedYears.contains)
        .fold<int>(0, (sum, y) => sum + (_yearCounts[y] ?? 0));

    return Scaffold(
      appBar: AppBar(title: const Text('Xのアーカイブを取り込む')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Xからダウンロードしたアーカイブの中の「data/tweets.js」を選んでください。'
            '年を選んで取り込めます。同じ投稿は、何度取り込んでも増えません。',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: busy ? null : _pick,
            icon: const Icon(Icons.folder_open),
            label: const Text('tweets.js を選ぶ'),
          ),
          if (_reading) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 8),
            const Center(child: Text('読み込み中…(大きいファイルは時間がかかります)')),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (_posts != null && years.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              '${_posts!.length}件の投稿が見つかりました。取り込む年を選んでください。',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            for (final year in years)
              CheckboxListTile(
                dense: true,
                value: _selectedYears.contains(year),
                onChanged: busy
                    ? null
                    : (checked) => setState(() {
                          if (checked == true) {
                            _selectedYears.add(year);
                          } else {
                            _selectedYears.remove(year);
                          }
                        }),
                title: Text('$year年'),
                secondary: Text('${_yearCounts[year]}件'),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: busy || selectedCount == 0 ? null : _import,
              child: Text('$selectedCount件を取り込む'),
            ),
          ],
          if (_importing) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _progressTotal == 0 ? null : _progress / _progressTotal,
            ),
            const SizedBox(height: 8),
            Text('$_progress / $_progressTotal件'),
          ],
          if (_resultMessage != null) ...[
            const SizedBox(height: 16),
            Text(_resultMessage!),
          ],
        ],
      ),
    );
  }
}
