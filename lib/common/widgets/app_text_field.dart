import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:auto_diary_ai/common/constants/app_colors.dart';
import 'package:auto_diary_ai/common/constants/app_sizes.dart';

/// 入力欄(項目名を、欄の上に出す)
///
/// 1行の欄は、高さ52。[height]を渡すと、その高さの、複数行の欄になる。
/// 補足の文字は、欄の下に出す。入力中の枠は、ネイビー(アプリ共通の入力欄の見た目)
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hintText,
    this.helperText,
    this.height,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
  });

  final String label;
  final TextEditingController? controller;
  final String? hintText;

  /// 欄の下に出す、補足
  final String? helperText;

  /// 複数行の欄の高さ(渡さないと、1行の欄)
  final double? height;

  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final multiline = height != null;

    final field = TextField(
      controller: controller,
      keyboardType: multiline ? TextInputType.multiline : keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      expands: multiline,
      maxLines: multiline ? null : 1,
      minLines: multiline ? null : 1,
      textAlignVertical: multiline ? TextAlignVertical.top : TextAlignVertical.center,
      style: const TextStyle(fontSize: 16, color: AppColors.text),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(fontSize: 16, color: AppColors.mutedText),
        counterText: '',
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSizes.space16,
          vertical: multiline ? AppSizes.space16 : 0,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSizes.space4,
            bottom: AppSizes.space8,
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.52,
              color: AppColors.textSub,
            ),
          ),
        ),
        SizedBox(height: height ?? 52, child: field),
        if (helperText != null)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSizes.space4,
              top: AppSizes.space8,
            ),
            child: Text(
              helperText!,
              style: const TextStyle(fontSize: 12, color: AppColors.textSub),
            ),
          ),
      ],
    );
  }
}
