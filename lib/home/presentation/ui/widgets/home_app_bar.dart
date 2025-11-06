import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../l10n/app_localizations.dart';
import 'month_dropdown.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<String> months;
  final String selectedMonth;
  final ValueChanged<String> onMonthChanged;

  const HomeAppBar({
    super.key,
    required this.months,
    required this.selectedMonth,
    required this.onMonthChanged,
  });

  @override
  Size get preferredSize => const Size.fromHeight(100);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        AppLocalizations.of(context)?.appTitle ?? '',
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
        child: MonthDropdown(
          months: months,
          selectedMonth: selectedMonth,
          onChanged: onMonthChanged,
        ),
      ),
    );
  }
}
