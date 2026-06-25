import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:auto_diary_ai/common/constants/app_colors.dart';
import 'package:auto_diary_ai/common/constants/app_sizes.dart';

class ThemeUtil {
  static ThemeData appTheme() {
    final base = FlexThemeData.light(
      scheme: FlexScheme.sanJuanBlue,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      cardColor: AppColors.surface,
      textTheme: GoogleFonts.notoSansTextTheme(),

      appBarTheme: AppBarTheme(
        backgroundColor: base.primaryColor,
        titleTextStyle: GoogleFonts.notoSans(
          fontSize: AppSizes.fontSize20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
    );
  }
}
