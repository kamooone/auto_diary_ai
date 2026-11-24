import 'package:flutter/material.dart';
import '../../../ads/presentation/banner_ad_view.dart';
import '../../../tutorial/application/tutorial_providers.dart';
import '../../../tutorial/presentation/help_icon_tutorial.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../common/constants/app_colors.dart';
import '../../../../common/constants/app_sizes.dart';
import '../../../../common/widgets/app_buttons.dart';
import '../../../../common/widgets/app_card.dart';
import '../../../plan/application/providers/plan_provider.dart';
import '../../application/providers/device_link_provider.dart';
import '../../application/providers/pairing_provider.dart';
import 'points_guide_page.dart';

/// Webのアカウント(ポイント・トークン)との紐づけ
///
/// ポイントの獲得とトークンへの交換は、すべてWebで行う。
/// アプリは、紐づけたアカウントのトークン残高を使うだけ。
class PointsPage extends ConsumerStatefulWidget {
  const PointsPage({super.key});

  @override
  ConsumerState<PointsPage> createState() => _PointsPageState();
}

class _PointsPageState extends ConsumerState<PointsPage> {
  // チュートリアルで明るくする「?」アイコン
  final _helpKey = GlobalKey();

  // この画面のチュートリアルの印(見たかどうかを覚えるときの名前)
  static const _tutorialId = 'points';

  @override
  void initState() {
    super.initState();

    // トークン残高を、最新にする
    Future.microtask(() => ref.read(usageProvider.notifier).refresh());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showHelpIconTutorialOnce(
        context,
        store: ref.read(tutorialSeenStoreProvider),
        tutorialId: _tutorialId,
        screenTitle: 'ポイント・ゲーム',
        screenBody:
            'ゲームで遊んで貯めたポイントは、AIが日記を書くときに使う「トークン」に交換できます。\n\n'
            'この画面で、アカウントとの紐づけができます。',
        helpKey: _helpKey,
        helpBody: 'ポイントとトークンの、くわしい使い方は、画面の右上の「?」から、いつでも確認できます。',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLinked = ref.watch(deviceLinkProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("ポイント・ゲーム"),
        actions: [
          IconButton(
            key: _helpKey,
            tooltip: "ポイントとトークンの使い方",
            icon: const Icon(Icons.help_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const PointsGuidePage()),
            ),
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
          _Description(isLinked: isLinked),
          const SizedBox(height: AppSizes.space16),
          if (isLinked) const _LinkedCard() else const _PairingCard(),
          const SizedBox(height: AppSizes.space16),
          // ポイントは、ゲームで遊ぶと貯まる(ゲームの紹介は、Webのページにある)
          Consumer(
            builder: (context, ref, _) => SecondaryButton(
              icon: Icons.sports_esports_outlined,
              label: "ゲームで遊んで、ポイントを貯める",
              onPressed: () => _openWeb(context, ref, games: true),
            ),
          ),
        ],
      ),
    );
  }
}

/// 画面の上の説明
/// 伝える順番: ①ポイントを貯めるにはアカウントが必要(紐づけ済みのときは出さない)
/// → ②ポイントはトークンに交換できる → ③ポイントはゲームで遊ぶと貯まる
class _Description extends StatelessWidget {
  const _Description({required this.isLinked});

  final bool isLinked;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 15,
      height: 1.8,
      color: AppColors.textSub,
    );

    final paragraphs = [
      // 紐づけ済みの人には、アカウントが必要なことは、もう分かっているので出さない
      if (!isLinked) "ポイントを貯めるには、アカウントが必要です。",
      "貯めたポイントは、AIが日記を書くときに使う「トークン」に交換できます。",
      "ポイントは、ゲームで遊ぶと貯まります。",
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (index, text) in paragraphs.indexed) ...[
            if (index > 0) const SizedBox(height: AppSizes.space8),
            Text(text, style: style),
          ],
        ],
      ),
    );
  }
}

Future<void> _openWeb(
  BuildContext context,
  WidgetRef ref, {
  String? code,
  bool games = false,
}) async {
  final messenger = ScaffoldMessenger.of(context);

  final base = ref.read(pointsWebUrlProvider);
  final opened = await launchUrl(
    games ? pointsGamesUri(base) : pointsWebUri(base, code: code),
    mode: LaunchMode.externalApplication,
  ).catchError((_) => false);

  if (!opened) {
    messenger.showSnackBar(const SnackBar(content: Text("ページを開けませんでした")));
  }
}

/// 紐づけ済み
class _LinkedCard extends ConsumerWidget {
  const _LinkedCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usage = ref.watch(usageProvider);

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardHeader(title: "アカウントと紐づけ済み"),
          const SizedBox(height: AppSizes.space16),
          Text(
            usage == null
                ? "トークン残高を取得できていません"
                : "トークン残高: ${_number(usage.tokenBalance)}",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.navyDark,
            ),
          ),
          const SizedBox(height: AppSizes.space24),
          PrimaryButton(
            icon: Icons.open_in_new,
            label: "ポイントを交換する",
            onPressed: () => _openWeb(context, ref),
          ),
          const SizedBox(height: AppSizes.space12),
          SecondaryButton(
            label: "この端末の紐づけを解除",
            onPressed: () => _confirmUnlink(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmUnlink(BuildContext context, WidgetRef ref) async {
    final agreed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text("紐づけを解除しますか？"),
        content: const Text(
          "この端末では、アカウントのトークンを使えなくなります。"
          "トークンの残高は、アカウントに残ります。"
          "ポイントのページの端末一覧からも、この端末が消えます。",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("やめる"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("解除する"),
          ),
        ],
      ),
    );

    if (agreed != true) return;

    await ref.read(deviceLinkProvider.notifier).unlinkFromServer();
    await ref.read(usageProvider.notifier).refresh();
  }
}

/// 未紐づけ。コードを発行して、Webで入力してもらう
class _PairingCard extends ConsumerWidget {
  const _PairingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pairing = ref.watch(pairingProvider);

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardHeader(title: "アカウントと紐づける"),
          const SizedBox(height: AppSizes.space16),
          ..._content(context, ref, pairing),
        ],
      ),
    );
  }

  List<Widget> _content(
    BuildContext context,
    WidgetRef ref,
    PairingState pairing,
  ) {
    final theme = Theme.of(context);
    final notifier = ref.read(pairingProvider.notifier);

    switch (pairing.phase) {
      case PairingPhase.idle:
      case PairingPhase.expired:
      case PairingPhase.failed:
        return [
          if (pairing.phase == PairingPhase.expired)
            _message(theme, "コードの有効期限が切れました。もう一度発行してください。"),
          if (pairing.phase == PairingPhase.failed)
            _message(theme, "コードを発行できませんでした。通信を確認して、もう一度お試しください。"),
          // 手順(番号の丸を、点線でつなぐ)
          const _Steps(
            steps: [
              "下のボタンで、6桁のコードを発行します",
              "ポイントのページにログイン(アカウントがなければ作成)して、コードを入力します",
              "確認画面で、この端末であることを確かめて、紐づけます",
            ],
          ),
          const SizedBox(height: AppSizes.space24),
          PrimaryButton(
            icon: Icons.vpn_key_outlined,
            label: "コードを発行する",
            onPressed: notifier.start,
          ),
          const SizedBox(height: AppSizes.space12),
          SecondaryButton(
            icon: Icons.open_in_new,
            label: "ポイントのページを開く",
            onPressed: () => _openWeb(context, ref),
          ),
        ];

      case PairingPhase.starting:
        return const [Center(child: CircularProgressIndicator())];

      case PairingPhase.waiting:
        final code = pairing.session!.code;

        return [
          const Text(
            "ポイントのページにログインして、このコードを入力してください。",
            style: TextStyle(fontSize: 15, height: 1.8, color: AppColors.text),
          ),
          const SizedBox(height: AppSizes.space16),
          // 6桁のコード(1桁ずつ、淡いピンクの四角に入れる)
          _CodeBoxes(key: const Key('pairingCode'), code: code),
          const SizedBox(height: AppSizes.space12),
          Center(
            child: SizedBox(
              width: 200,
              child: SecondaryButton(
                icon: Icons.copy,
                label: "コードをコピー",
                onPressed: () => Clipboard.setData(ClipboardData(text: code)),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.space16),
          // 注意(有効期限など)
          Container(
            padding: const EdgeInsets.all(AppSizes.space12),
            decoration: BoxDecoration(
              color: AppColors.pageBackground,
              borderRadius: BorderRadius.circular(AppSizes.radius12),
              border: Border.all(color: AppColors.line),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.schedule, size: 18, color: AppColors.navy),
                ),
                SizedBox(width: AppSizes.space8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "有効期限は10分です。",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                        TextSpan(
                          text:
                              "紐づけが済むと、この画面が自動で切り替わります。"
                              "自分で発行したコード以外は、入力しないでください。",
                        ),
                      ],
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.8,
                      color: AppColors.textSub,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.space24),
          PrimaryButton(
            icon: Icons.open_in_new,
            label: "ポイントのページを開いて紐づける",
            // 同じ端末なら、コードを入力する手間を省く
            onPressed: () => _openWeb(context, ref, code: code),
          ),
          const SizedBox(height: AppSizes.space12),
          SecondaryButton(label: "キャンセル", onPressed: notifier.cancel),
        ];
    }
  }

  Widget _message(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.space12),
      child: Text(text, style: TextStyle(color: theme.colorScheme.error)),
    );
  }
}

/// カードの上の見出し(ピンクの丸にリンクのアイコンと、タイトル)
class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.pink,
          ),
          child: const Icon(Icons.link, size: 20, color: AppColors.navy),
        ),
        const SizedBox(width: AppSizes.space12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
        ),
      ],
    );
  }
}

/// 手順の一覧(左に番号の丸、丸と丸の間は点線)
class _Steps extends StatelessWidget {
  const _Steps({required this.steps});

  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 28,
                  child: Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.navy,
                        ),
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      if (i < steps.length - 1)
                        Expanded(
                          child: CustomPaint(
                            size: const Size(2, double.infinity),
                            painter: _DotsPainter(),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.space12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: 3,
                      bottom: i < steps.length - 1 ? AppSizes.space12 : 0,
                    ),
                    child: Text(
                      steps[i],
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.timelineDots
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (var y = 3.0; y < size.height - 3; y += 5) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, y + 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 6桁のコードを、1桁ずつの四角で並べる
class _CodeBoxes extends StatelessWidget {
  const _CodeBoxes({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'コード ${code.split('').join(' ')}',
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final digit in code.split(''))
            Flexible(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                constraints: const BoxConstraints(maxWidth: 44),
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.pink,
                  borderRadius: BorderRadius.circular(AppSizes.radius12),
                ),
                child: Text(
                  digit,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyDark,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// 3桁ごとにカンマで区切る
String _number(int value) {
  return value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
}
