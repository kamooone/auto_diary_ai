import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/home_providers.dart';
import '../widgets/diary_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();

    final diaryItems = ref.read(diaryProvider);
    final months = diaryItems
        .map((item) => item.date.substring(0, 7))
        .toSet()
        .toList()
      ..sort();

    final selectedMonth = ref.read(selectedMonthProvider);
    final initialPage = months.indexOf(selectedMonth);
    _pageController = PageController(initialPage: initialPage);
  }

  @override
  Widget build(BuildContext context) {
    final diaryItems = ref.watch(diaryProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);

    final months = diaryItems
        .map((item) => item.date.substring(0, 7))
        .toSet()
        .toList()
      ..sort();

    final filteredItemsPerMonth = {
      for (var month in months)
        month: diaryItems.where((item) => item.date.startsWith(month)).toList()
    };

    void jumpToMonth(int index) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      ref.read(selectedMonthProvider.notifier).setMonth(months[index]);
    }

    return Theme(
      data: FlexThemeData.light(
        scheme: FlexScheme.mandyRed,
        surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
        blendLevel: 15,
        appBarOpacity: 0.95,
        subThemesData: const FlexSubThemesData(
          cardElevation: 6,
          cardRadius: 16,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        fontFamily: GoogleFonts.notoSans().fontFamily,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'AIフォトダイアリー',
            style: GoogleFonts.notoSans(fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {},
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text('表示月: '),
                  DropdownButton<String>(
                    value: selectedMonth,
                    onChanged: (value) {
                      if (value != null) {
                        final index = months.indexOf(value);
                        jumpToMonth(index);
                      }
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
                ],
              ),
            ),
          ),
        ),
        body: PageView.builder(
          controller: _pageController,
          itemCount: months.length,
          onPageChanged: (index) {
            ref.read(selectedMonthProvider.notifier).setMonth(months[index]);
          },
          itemBuilder: (context, pageIndex) {
            final items = filteredItemsPerMonth[months[pageIndex]]!;
            return AnimationLimiter(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return DiaryCard(item: item, index: index);
                },
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          child: const Icon(Icons.add_a_photo),
        ),
      ),
    );
  }
}
