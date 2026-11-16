import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../common/constants/app_colors.dart';
import '../../../../common/constants/app_sizes.dart';
import '../../../../common/widgets/app_buttons.dart';
import '../../../../common/widgets/app_card.dart';
import '../../../../common/widgets/select_row.dart';
import '../../../diary_create/domain/entities/photo.dart';
import '../../../diary_create/presentation/ui/widgets/photo_selection_card.dart';
import '../../application/providers/memo_providers.dart';
import '../../domain/entities/memo.dart';

/// ひとことメモを追加・修正する、下から出るシート
///
/// [memo]を渡すと修正、渡さないと追加。保存・修正できたときは、一覧を読み込み直す
Future<void> showMemoEditDialog(BuildContext context, {Memo? memo}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.pageBackground,
    barrierColor: AppColors.scrim,
    // キーボードが出ても、入力欄が隠れないようにする
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _MemoEditDialog(memo: memo),
  );
}

class _MemoEditDialog extends ConsumerStatefulWidget {
  const _MemoEditDialog({this.memo});

  final Memo? memo;

  @override
  ConsumerState<_MemoEditDialog> createState() => _MemoEditDialogState();
}

class _MemoEditDialogState extends ConsumerState<_MemoEditDialog> {
  late final _controller = TextEditingController(text: widget.memo?.text ?? '');

  // 追加したときの時刻(あとから変えられる)
  late DateTime _createdAt = widget.memo?.createdAt ?? DateTime.now();

  late List<Photo> _photos = [
    for (final id in widget.memo?.photoIds ?? const <String>[])
      Photo(id: id, createdAt: _createdAt),
  ];

  var _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  String get _dateText {
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    return "${_createdAt.year}/${_createdAt.month}/${_createdAt.day}"
        "（${weekdays[_createdAt.weekday - 1]}） "
        "${_two(_createdAt.hour)}:${_two(_createdAt.minute)}";
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: _createdAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_createdAt),
    );
    if (time == null || !mounted) return;

    setState(() {
      _createdAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSaving) return;

    setState(() => _isSaving = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final repository = ref.read(memoRepositoryProvider);

    final saved = Memo(
      id: widget.memo?.id,
      text: text,
      createdAt: _createdAt,
      photoIds: [for (final photo in _photos) photo.id],
    );

    try {
      if (saved.id == null) {
        await repository.save(saved);
      } else {
        await repository.update(saved);
      }
    } catch (e) {
      debugPrint(e.toString());

      if (!mounted) return;
      setState(() => _isSaving = false);
      messenger.showSnackBar(const SnackBar(content: Text("保存に失敗しました")));
      return;
    }

    ref.invalidate(allMemosProvider);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.memo != null;
    final canSave = _controller.text.trim().isNotEmpty && !_isSaving;

    return SafeArea(
      child: SingleChildScrollView(
        // キーボードの分だけ、持ち上げる
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.space16,
            AppSizes.space12,
            AppSizes.space16,
            AppSizes.space24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // つまみ
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.sheetHandle,
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.space16),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.space8,
                ),
                child: Text(
                  isEditing ? "ひとことメモを修正" : "ひとことメモを追加",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.space16),

              // ---------- 入力欄(高さ120。文字数は、右下に小さく)
              SizedBox(
                height: 120,
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  maxLength: Memo.maxLength,
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(fontSize: 16, color: AppColors.text),
                  decoration: const InputDecoration(
                    hintText: "今日のできごとや気持ちを、ひとこと",
                    hintStyle: TextStyle(
                      fontSize: 16,
                      color: AppColors.mutedText,
                    ),
                    counterText: '',
                    contentPadding: EdgeInsets.all(AppSizes.space16),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  top: AppSizes.space4,
                  right: AppSizes.space8,
                  bottom: AppSizes.space12,
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "${_controller.text.characters.length} / ${Memo.maxLength}",
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSub,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),

              // ---------- 日時と写真
              AppCard(
                child: Column(
                  children: [
                    SelectRow(
                      icon: Icons.schedule,
                      label: "記録する日時",
                      value: _dateText,
                      onTap: _pickDateTime,
                      trailing: const Padding(
                        padding: EdgeInsets.only(right: AppSizes.space4),
                        child: Text(
                          "変更",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                    ),
                    const RowDivider(),
                    // 写真は、撮影日に関係なく選べる(日記の編集と同じ)
                    PhotoSelectionRows(
                      photos: _photos,
                      onChanged: (photos) => setState(() => _photos = photos),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.space24),

              // ---------- ボタン(同じ幅で、横に並べる)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: SecondaryButton(
                        label: "キャンセル",
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.space12),
                  Expanded(
                    child: PrimaryButton(
                      label: isEditing ? "保存" : "追加する",
                      onPressed: canSave ? _save : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
