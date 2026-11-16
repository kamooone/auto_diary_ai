import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../common/constants/app_colors.dart';
import '../../../../common/constants/app_sizes.dart';
import '../../../../common/widgets/app_buttons.dart';
import '../../../../common/widgets/app_card.dart';
import '../../../../common/widgets/app_tag.dart';
import '../../../../common/widgets/app_text_field.dart';
import '../../../ai/application/providers/ai_model_provider.dart';
import '../../domain/services/diary_copy_text.dart';
import '../providers/diary_create_provider.dart';
import '../viewmodel/diary_create_view_model.dart';
import 'widgets/generation_progress.dart';

/// AIが書いた日記を確認・修正して保存する画面
class DiaryResultScreen extends ConsumerStatefulWidget {
  const DiaryResultScreen({super.key});

  @override
  ConsumerState<DiaryResultScreen> createState() => _DiaryResultScreenState();
}

class _DiaryResultScreenState extends ConsumerState<DiaryResultScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  // 書き終えたあと、ゲージを100%まで満たしている間(満たし終えたら、確認画面にする)
  var _isFinishing = false;

  @override
  void initState() {
    super.initState();

    // すでに書き上がっている場合は、その内容を表示する
    final state = ref.read(diaryCreateProvider);
    if (_isCompleted(state)) {
      _showGenerated(state);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  bool _isCompleted(DiaryCreateState state) {
    return !state.isLoading &&
        state.errorMessage == null &&
        state.generatedDiary.isNotEmpty;
  }

  void _showGenerated(DiaryCreateState state) {
    _titleController.text = state.generatedTitle;
    _contentController.text = state.generatedDiary;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(diaryCreateProvider);

    // AIが書き終えたら、修正できるよう入力欄に反映する
    ref.listen(diaryCreateProvider, (previous, next) {
      if (previous?.isLoading == true && _isCompleted(next)) {
        _showGenerated(next);
        setState(() => _isFinishing = true);
      }
    });

    final isCompleted = _isCompleted(state) && !_isFinishing;

    return Scaffold(
      appBar: AppBar(title: Text(state.generatedByAi ? "AI日記の確認" : "日記の確認")),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: _buildBody(context, state),
      ),
      // ボタンは、画面の下に固定する(本文が長くても、いつでも押せる)
      bottomNavigationBar: isCompleted
          ? Container(
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  // 本文が空の日記は保存できない
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _contentController,
                    builder: (context, value, child) {
                      final isEmpty = value.text.trim().isEmpty;

                      return Row(
                        children: [
                          // ほかのAIなどで修正するために、書かれた内容をコピーできる
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 52,
                              child: SecondaryButton(
                                icon: Icons.copy,
                                label: "コピー",
                                onPressed: isEmpty ? null : _copy,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: PrimaryButton(
                              icon: Icons.save_outlined,
                              label: "この内容で保存する",
                              onPressed: isEmpty ? null : _save,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            )
          : null,
    );
  }

  // 修正した内容も含めて、今の入力欄のタイトルと本文をコピーする
  Future<void> _copy() async {
    final messenger = ScaffoldMessenger.of(context);

    await Clipboard.setData(
      ClipboardData(
        text: DiaryCopyText.format(
          title: _titleController.text,
          content: _contentController.text,
        ),
      ),
    );

    messenger.showSnackBar(const SnackBar(content: Text("タイトルと本文をコピーしました")));
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final viewModel = ref.read(diaryCreateProvider.notifier);
    final saved = await viewModel.saveGeneratedDiary(
      title: _titleController.text,
      content: _contentController.text,
    );

    messenger.showSnackBar(
      SnackBar(content: Text(saved ? "日記を保存しました" : "保存に失敗しました")),
    );

    // 保存できたら、入力画面も閉じてホームに戻る
    if (saved) {
      // 次に日記を作るときに、前回の選択が残らないよう初期状態に戻す
      viewModel.resetAfterSave();
      navigator.popUntil((route) => route.isFirst);
    }
  }

  Widget _buildBody(BuildContext context, DiaryCreateState state) {
    // 書き終えたあとも、ゲージを100%まで満たすあいだは、作成中の表示にする
    if (state.isLoading || _isFinishing) {
      return GenerationProgress(
        expectedSeconds: state.expectedSeconds,
        // AIを使うときは、使っているAIのモデル名を出す
        modelName: state.generatedByAi
            ? ref.read(aiModelProvider).modelName
            : null,
        isDone: !state.isLoading,
        onFinished: () {
          if (mounted) setState(() => _isFinishing = false);
        },
      );
    }

    final errorMessage = state.errorMessage;
    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              errorMessage,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("入力画面に戻る"),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSizes.space24),
      children: [
        // お知らせ(使用したモデルは、小さな札で)
        AppCard(
          padding: const EdgeInsets.all(AppSizes.space16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.pink,
                ),
                child: Icon(
                  state.generatedByAi
                      ? Icons.auto_awesome
                      : Icons.menu_book_outlined,
                  size: 20,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(width: AppSizes.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        state.generatedByAi
                            ? "AIが書いた内容です。必要なら修正してから保存してください。"
                            : "選んだ日記を日付順につなげた内容です。必要なら修正してから保存してください。",
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    // 使用したモデル(AIを使わないときや、分からないときは出さない)
                    if (state.generatedByAi && state.generatedModel.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSizes.space8),
                        child: AppTag(state.generatedModel),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.space24),
        AppTextField(label: "タイトル", controller: _titleController, bold: true),
        const SizedBox(height: AppSizes.space24),
        // 本文(項目名の右に、文字数)
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.space4,
            0,
            AppSizes.space4,
            AppSizes.space8,
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  "本文",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.52,
                    color: AppColors.textSub,
                  ),
                ),
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _contentController,
                builder: (context, value, child) => Text(
                  "${value.text.characters.length}文字",
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSub,
                  ),
                ),
              ),
            ],
          ),
        ),
        TextField(
          controller: _contentController,
          keyboardType: TextInputType.multiline,
          minLines: 10,
          maxLines: null,
          style: const TextStyle(
            fontSize: 15,
            height: 1.9,
            color: AppColors.text,
          ),
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.all(AppSizes.space16),
          ),
        ),
      ],
    );
  }
}
