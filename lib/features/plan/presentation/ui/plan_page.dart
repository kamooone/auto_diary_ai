import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/plan_provider.dart';
import '../../domain/entities/plan_product.dart';
import '../../domain/entities/plan_type.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../widgets/usage_meter.dart';

/// プランの確認と、有料プランの購入
class PlanPage extends ConsumerStatefulWidget {
  const PlanPage({super.key});

  @override
  ConsumerState<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends ConsumerState<PlanPage> {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    // 最新の使用量を取得する
    Future.microtask(() => ref.read(usageProvider.notifier).refresh());
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(planTypeProvider);
    final usage = ref.watch(usageProvider);
    final products = ref.watch(planProductsProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text("プラン")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("現在のプラン", style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 2),
                  Text(
                    plan.label,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  UsageMeter(usage: usage),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ---------- プランの違い
          const _Comparison(),
          const SizedBox(height: 16),

          // ---------- 購入
          if (!plan.isPaid) ...[
            if (products.isEmpty)
              const FilledButton(
                onPressed: null,
                child: Text("有料プランに変更(準備中)"),
              )
            else
              for (final product in products)
                FilledButton(
                  onPressed: _isProcessing ? null : () => _buy(product),
                  child: Text(_buyLabel(product)),
                ),
            const SizedBox(height: 8),
          ],
          OutlinedButton(
            onPressed: _isProcessing ? null : _restore,
            child: const Text("購入を復元する"),
          ),
          const SizedBox(height: 8),
          Text(
            "有料プランは、Google PlayまたはApp Storeの定期購入です。"
            "解約は各ストアのアカウント設定から行えます。",
            style: Theme.of(context).textTheme.bodySmall,
          ),

          // ---------- 動作確認用
          // 決済を導入するまで、プランによる画面の違いを確かめられるようにする
          const Divider(height: 32),
          Text("動作確認用", style: Theme.of(context).textTheme.bodySmall),
          SegmentedButton<PlanType>(
            segments: [
              for (final type in PlanType.values)
                ButtonSegment(value: type, label: Text(type.label)),
            ],
            selected: {plan},
            onSelectionChanged: (selection) {
              ref.read(planTypeProvider.notifier).setPlan(selection.first);
            },
          ),
        ],
      ),
    );
  }

  String _buyLabel(PlanProduct product) {
    return [
      "有料プランに変更",
      "${product.price}${product.period == null ? "" : " / ${product.period}"}",
    ].join("  ");
  }

  Future<void> _buy(PlanProduct product) async {
    await _run(() => ref.read(purchaseRepositoryProvider).buy(product));
  }

  Future<void> _restore() async {
    await _run(() => ref.read(purchaseRepositoryProvider).restore());
  }

  Future<void> _run(Future<PurchaseOutcome> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isProcessing = true);
    final outcome = await action();
    if (!mounted) return;
    setState(() => _isProcessing = false);

    final message = switch (outcome) {
      PurchaseOutcome.purchased => "ありがとうございます。プランを確認しています",
      PurchaseOutcome.pending => "お支払いの承認待ちです。承認されると有料プランになります",
      PurchaseOutcome.failed => "購入できませんでした。時間をおいて、もう一度お試しください",
      PurchaseOutcome.unavailable => "この端末では、現在購入できません",
      PurchaseOutcome.cancelled => null,
    };

    if (message != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }

    // 購入できた場合は、サーバーが判定したプランと使用量を取り直す
    if (outcome == PurchaseOutcome.purchased) {
      await ref.read(usageProvider.notifier).refresh();
    }
  }
}

/// 無料プランと有料プランの違い
class _Comparison extends StatelessWidget {
  const _Comparison();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;

    Widget row(String title, String free, String paid) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 4, child: Text(title, style: style)),
            Expanded(flex: 3, child: Text(free, style: style)),
            Expanded(
              flex: 3,
              child: Text(
                paid,
                style: style?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            row("", "無料", "有料"),
            const Divider(height: 1),
            row("AIの使用量", "月ごとの上限あり", "無料より大幅に多い"),
            const Divider(height: 1),
            row("AIに渡す日記の期間", "選んだ1日分", "複数日分をまとめて"),
          ],
        ),
      ),
    );
  }
}
