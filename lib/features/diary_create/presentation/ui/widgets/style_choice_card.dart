import 'package:flutter/material.dart';

/// 書き方の選択肢の一覧(選んでいるものには、印を付ける)
class StyleChoiceCard<T> extends StatelessWidget {
  const StyleChoiceCard({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.description,
    required this.onSelected,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) label;
  final String Function(T value) description;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          for (final value in values)
            ListTile(
              leading: Icon(
                value == selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: value == selected
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: Text(label(value)),
              subtitle: Text(description(value)),
              onTap: () => onSelected(value),
            ),
        ],
      ),
    );
  }
}
