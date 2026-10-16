import 'package:flutter/material.dart';
import '../../../share/domain/entities/shared_post.dart';
import '../../domain/services/day_grouper.dart';
import 'widgets/day_header.dart';

/// AIに渡すXの投稿を選択する画面
/// 「確定」で選択した投稿の一覧を返す
class PostSelectPage extends StatefulWidget {
  const PostSelectPage({
    super.key,
    required this.posts,
    required this.initialSelection,
  });

  final List<SharedPost> posts;
  final List<SharedPost> initialSelection;

  @override
  State<PostSelectPage> createState() => _PostSelectPageState();
}

class _PostSelectPageState extends State<PostSelectPage> {
  late final _selected = {...widget.initialSelection};

  // 日付ごとの投稿
  late final _days = groupByDay<SharedPost>(widget.posts, (e) => e.receivedAt);

  // 日付ごとの見出しと投稿を、1列に並べたもの
  late final List<Object> _rows = [
    for (final day in _days) ...[day, ...day.items],
  ];

  // その日の投稿が、すべて選択されていれば解除し、そうでなければすべて選択する
  void _toggleDay(DayGroup<SharedPost> day) {
    setState(() {
      if (day.items.every(_selected.contains)) {
        _selected.removeAll(day.items);
      } else {
        _selected.addAll(day.items);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAllSelected = _selected.length == widget.posts.length;

    return Scaffold(
      appBar: AppBar(
        title: Text("Xの投稿 (${_selected.length}/${widget.posts.length})"),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                if (isAllSelected) {
                  _selected.clear();
                } else {
                  _selected.addAll(widget.posts);
                }
              });
            },
            child: Text(isAllSelected ? "すべて解除" : "すべて選択"),
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: _rows.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final row = _rows[index];

          // 日付の見出し
          if (row is DayGroup<SharedPost>) {
            return DayHeader(
              date: row.date,
              selectedCount: row.items.where(_selected.contains).length,
              totalCount: row.items.length,
              onToggle: () => _toggleDay(row),
            );
          }

          final post = row as SharedPost;

          return CheckboxListTile(
            value: _selected.contains(post),
            title: Text(
              post.text.isEmpty ? "(テキストなし)" : post.text,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(_time(post.receivedAt)),
            onChanged: (checked) {
              setState(() {
                if (checked ?? false) {
                  _selected.add(post);
                } else {
                  _selected.remove(post);
                }
              });
            },
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: ElevatedButton(
            // 元の並び順のまま返す
            onPressed: () => Navigator.of(context).pop(
              widget.posts.where(_selected.contains).toList(),
            ),
            child: Text("確定（${_selected.length}件）"),
          ),
        ),
      ),
    );
  }

  String _time(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "${time.month}/${time.day} $hour:$minute";
  }
}
