import 'package:flutter/material.dart';
import 'package:auto_diary_ai/common/constants/app_colors.dart';
import 'package:auto_diary_ai/common/constants/app_sizes.dart';

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.horizontal16, vertical: AppSizes.vertical8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.horizontal12, vertical: AppSizes.vertical4),
            decoration: BoxDecoration(
              color: AppColors.dropdownBackground,
              borderRadius: BorderRadius.circular(AppSizes.circular8),
              border: Border.all(color: AppColors.dropdownBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedMonth,
                isExpanded: false,
                icon: const Icon(Icons.arrow_drop_down),
                dropdownColor: AppColors.dropdownMenu,
                onChanged: (value) {
                  if (value != null) onChanged(value);
                },
                items: months
                    .map(
                      (month) => DropdownMenuItem(
                    value: month,
                    child: Text(month),
                  ),
                )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
