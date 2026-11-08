import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../domain/entities/diary_length.dart';

/// 文字数の目安(任意)を、数字で入力する欄
class LengthField extends StatefulWidget {
  const LengthField({
    super.key,
    required this.initialChars,
    required this.onChanged,
  });

  /// 最初に表示する文字数(指定しないときは0)
  final int initialChars;

  /// 入力のたびに、文字数(指定しない・数字でないときは0)を渡す
  final ValueChanged<int> onChanged;

  @override
  State<LengthField> createState() => _LengthFieldState();
}

class _LengthFieldState extends State<LengthField> {
  late final _controller = TextEditingController(
    text: widget.initialChars > 0 ? '${widget.initialChars}' : '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: "文字数の目安(任意)",
        hintText: "例: 800",
        suffixText: "文字",
        border: const OutlineInputBorder(),
        helperText: "あくまで目安です。この通りの文字数になるとは限りません",
        helperMaxLines: 2,
        counterText: '',
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(DiaryLength.maxDigits),
      ],
      onChanged: (text) {
        setState(() {});
        widget.onChanged(DiaryLength.parse(text));
      },
    );
  }
}
