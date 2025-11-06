import 'package:flutter/material.dart';

class MonthDropdown extends StatelessWidget {
  final List<String> months;
  final String selectedMonth;
  final ValueChanged<String> onChanged;

  const MonthDropdown({
    super.key,
    required this.months,
    required this.selectedMonth,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DropdownButton<String>(
          value: selectedMonth,
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
          items: months
              .map((month) => DropdownMenuItem(
            value: month,
            child: Text(month),
          ))
              .toList(),
        ),
      ],
    );
  }
}
