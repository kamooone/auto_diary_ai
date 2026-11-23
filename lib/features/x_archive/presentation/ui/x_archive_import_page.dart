import 'package:file_picker/file_picker.dart';
import '../../../ads/presentation/banner_ad_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/constants/app_colors.dart';
import '../../../../common/constants/app_sizes.dart';
import '../../../../common/widgets/app_buttons.dart';
import '../../../../common/widgets/app_card.dart';
import '../../../../core/app_info/install_date_provider.dart';
import '../../../../core/database/isar_provider.dart';
import '../../application/providers/x_archive_providers.dart';
import '../../application/services/x_archive_file_reader.dart';
import '../../domain/entities/x_archive_post.dart';
import '../../domain/services/x_archive_summary.dart';
import 'x_archive_guide_page.dart';

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
      final result = await ref
          .read(xArchiveRepositoryProvider)
          .import(
            target,
            onProgress: (done) {
              if (mounted) setState(() => _progress = done);
            },
          );
      // 取り込んだ投稿の、いちばん古い日まで、日記にする期間などで選べるようにする
      // (アプリを使い始めた日より前の投稿も、選べるようにするため)
      final oldest = oldestPostDayJst(target);
      if (oldest != null) {
        await moveInstallDateEarlier(
          ref.read(isarProvider),
          ref.read(installDateProvider.notifier),
          oldest,
        );
      }
      if (!mounted) return;
      final first = ref.read(installDateProvider);
      setState(() {
        _resultMessage =
            '${result.added}件を取り込みました'
            '(取り込み済みで飛ばした分: ${result.skipped}件)\n'
            '日記にする期間などは、${first.year}年${first.month}月${first.day}日から選べます';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '取り込めませんでした: $e');
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  void _openGuide() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const XArchiveGuidePage()));
  }

  @override
  Widget build(BuildContext context) {
    final busy = _reading || _importing;
    final years = _yearCounts.keys.toList()..sort((a, b) => b.compareTo(a));
    final selectedCount = years
        .where(_selectedYears.contains)
        .fold<int>(0, (sum, y) => sum + (_yearCounts[y] ?? 0));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xのアーカイブを取り込む'),
        actions: [
          IconButton(
            tooltip: 'アーカイブの取り込み方',
            icon: const Icon(Icons.help_outline),
            onPressed: _openGuide,
          ),
        ],
      ),
      bottomNavigationBar: const SafeArea(child: BannerAdView(band: true)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.space16,
          20,
          AppSizes.space16,
          AppSizes.space24,
        ),
        children: [
          AppCard(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.pink,
                    ),
                    child: const Icon(
                      Icons.upload_file,
                      size: 30,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.space16),
                const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'Xからダウンロードしたアーカイブの中の '),
                      TextSpan(
                        text: 'data / tweets.js',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: ' を選んでください。'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.8,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: AppSizes.space16),
                PrimaryButton(
                  icon: Icons.folder_open,
                  label: 'tweets.js を選ぶ',
                  onPressed: busy ? null : _pick,
                ),
                const SizedBox(height: AppSizes.space12),
                // ヘッダーの「?」と同じ、取り込み方の画面へ
                Center(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppSizes.radius12),
                    onTap: _openGuide,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSizes.space12,
                        vertical: AppSizes.space8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.help_outline,
                            size: 18,
                            color: AppColors.navy,
                          ),
                          SizedBox(width: AppSizes.space4),
                          Flexible(
                            child: Text(
                              '取り込み方を見る',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navy,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // 読み込み中・結果の表示は、同じカードの中に、今の内容のまま出す
                if (_reading) ...[
                  const SizedBox(height: AppSizes.space16),
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: AppSizes.space8),
                  const Center(child: Text('読み込み中…(大きいファイルは時間がかかります)')),
                ],
                if (_error != null) ...[
                  const SizedBox(height: AppSizes.space16),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                if (_posts != null && years.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.space24),
                  Text(
                    '${_posts!.length}件の投稿が見つかりました。取り込む年を選んでください。',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: AppSizes.space8),
                  for (final year in years)
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
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
                  const SizedBox(height: AppSizes.space16),
                  PrimaryButton(
                    label: '$selectedCount件を取り込む',
                    onPressed: busy || selectedCount == 0 ? null : _import,
                  ),
                ],
                if (_importing) ...[
                  const SizedBox(height: AppSizes.space16),
                  LinearProgressIndicator(
                    value: _progressTotal == 0
                        ? null
                        : _progress / _progressTotal,
                  ),
                  const SizedBox(height: AppSizes.space8),
                  Text('$_progress / $_progressTotal件'),
                ],
                if (_resultMessage != null) ...[
                  const SizedBox(height: AppSizes.space16),
                  Text(_resultMessage!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
