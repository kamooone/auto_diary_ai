import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../diary_create/application/providers/diary_usecase_providers.dart';
import '../../../diary_create/domain/entities/photo.dart';
import '../../../diary_create/presentation/ui/widgets/photo_selection_card.dart';
import '../../application/providers/x_archive_providers.dart';
import '../../application/services/x_archive_photo_loader.dart';
import '../../domain/entities/x_archive_post.dart';
import '../../domain/services/x_archive_photo_matcher.dart';
import 'x_archive_post_formatter.dart';

/// 取り込んだ投稿の全文と、結びつけた写真を見る・変える画面
class XArchivePostDetailPage extends ConsumerStatefulWidget {
  const XArchivePostDetailPage({super.key, required this.post});

  final XArchivePost post;

  @override
  ConsumerState<XArchivePostDetailPage> createState() =>
      _XArchivePostDetailPageState();
}

class _XArchivePostDetailPageState
    extends ConsumerState<XArchivePostDetailPage> {
  late XArchivePost _post = widget.post;
  List<Photo>? _photos;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final photos = await loadXArchivePhotos(
      _post,
      ref.read(photoRepositoryProvider),
    );
    if (!mounted) return;
    setState(() => _photos = photos);
  }

  Future<void> _save(List<String>? ids) async {
    final repo = ref.read(xArchiveRepositoryProvider);
    await repo.updatePhotoIds(_post.tweetId, ids);
    final updated = await repo.find(_post.tweetId);
    if (!mounted || updated == null) return;
    setState(() {
      _post = updated;
      _photos = null;
    });
    await _loadPhotos();
  }

  @override
  Widget build(BuildContext context) {
    final range = const XArchivePhotoMatcher().window(_post.createdAt);
    final photos = _photos;
    final notes = XArchivePostFormatter.notes(_post);

    return Scaffold(
      appBar: AppBar(title: const Text('投稿')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            [XArchivePostFormatter.date(_post.createdAt), ...notes].join('  ・  '),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          SelectableText(_post.text.isEmpty ? '(本文なし)' : _post.text),
          const SizedBox(height: 16),
          if (photos == null)
            const Center(child: CircularProgressIndicator())
          else ...[
            PhotoSelectionCard(
              photos: photos,
              from: range.from,
              to: range.to,
              onChanged: (selected) => _save([for (final p in selected) p.id]),
            ),
            const SizedBox(height: 8),
            Text(
              _post.photoIds == null
                  ? '写真は、投稿の日時などから探した候補です。違っていたら、選び直せます。'
                  : 'あなたが選んだ写真です。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_post.photoIds != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => _save(null),
                  child: const Text('自動の候補に戻す'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
