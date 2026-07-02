import 'package:auto_diary_ai/features/share/data/models/shared_post_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import '../../core/database/isar_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _printAllPosts(WidgetRef ref) async {
    final isar = ref.read(isarProvider);

    final allPosts = await isar.sharedPostModels.where().findAll();

    debugPrint("========== ISAR 全データ ==========");

    if (allPosts.isEmpty) {
      debugPrint("データなし");
    }

    for (final post in allPosts) {
      debugPrint("ID: ${post.id}");
      debugPrint("URL: ${post.url}");
      debugPrint("TEXT: ${post.text}");
      debugPrint("DATE: ${post.receivedAt}");
      debugPrint("----------------------------");
    }

    debugPrint("==================================");
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.map),
            title: const Text("Map"),
            onTap: () {
              context.push('/map');
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text("DBデータを全部ログ表示"),
            subtitle: const Text("Isarに保存されている全データを出力"),
            onTap: () async {
              await _printAllPosts(ref);
            },
          ),
        ],
      ),
    );
  }
}