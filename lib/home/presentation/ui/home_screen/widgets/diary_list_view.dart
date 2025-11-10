import 'package:auto_diary_ai/core/constants/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../../data/models/diary_item.dart';
import 'diary_card.dart';

class DiaryListView extends StatelessWidget {
  final List<String> months;
  final Map<String, List<DiaryItem>> filteredItemsPerMonth;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;

  const DiaryListView({
    super.key,
    required this.months,
    required this.filteredItemsPerMonth,
    required this.pageController,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: pageController,
      itemCount: months.length,
      onPageChanged: onPageChanged,
      itemBuilder: (context, pageIndex) {
        final items = filteredItemsPerMonth[months[pageIndex]]!;
        return AnimationLimiter(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSizes.padding16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return DiaryCard(item: item, index: index);
            },
          ),
        );
      },
    );
  }
}
