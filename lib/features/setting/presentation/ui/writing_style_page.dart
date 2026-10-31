import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../diary_create/application/providers/diary_usecase_providers.dart';
import '../../../diary_create/domain/services/writing_style.dart';

/// AIが書く日記の文体の希望を、自由に書いて決める画面
/// (ふつうの日記も、まとめ日記も、同じ希望で書く)
class WritingStylePage extends ConsumerStatefulWidget {
  const WritingStylePage({super.key});

  @override
  ConsumerState<WritingStylePage> createState() => _WritingStylePageState();
}

class _WritingStylePageState extends ConsumerState<WritingStylePage> {
  final _controller = TextEditingController();
  var _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final text = await ref.read(writingStyleRepositoryProvider).load();
    if (!mounted) return;

    setState(() {
      _controller.text = text;
      _isLoaded = true;
    });
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);

    await ref.read(writingStyleRepositoryProvider).save(_controller.text);
    messenger.showSnackBar(const SnackBar(content: Text("保存しました")));
  }

  Future<void> _reset() async {
    await ref.read(writingStyleRepositoryProvider).reset();
    if (!mounted) return;

    setState(() => _controller.text = WritingStyle.defaultText);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("日記の文体")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            "AIが日記を書くときの、一人称や書き方の希望を、自由に書いてください。"
            "ふつうの日記も、まとめ日記も、この希望で書きます。\n"
            "最初に入っているのはサンプルです。気に入らなければ、書き換えてください。",
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            enabled: _isLoaded,
            decoration: const InputDecoration(
              labelText: "文体の希望",
              hintText: "例: 一人称は俺。です・ます調は使わない。体言止めを多めに使う",
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            keyboardType: TextInputType.multiline,
            minLines: 6,
            maxLines: 14,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoaded ? _save : null,
            child: const Text("保存する"),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _isLoaded ? _reset : null,
            child: const Text("サンプルに戻す"),
          ),
        ],
      ),
    );
  }
}
