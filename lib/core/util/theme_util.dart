import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import '../constants/theme_colors.dart';

class ThemeUtil {
  static ThemeData homeTheme() {
    return FlexThemeData.light(
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
    ).copyWith(
      scaffoldBackgroundColor: AppColors.background,
      cardColor: AppColors.surface,
      textTheme: GoogleFonts.notoSansTextTheme(),
    );
  }

  static ThemeData settingsTheme() {
    return FlexThemeData.light(
      scheme: FlexScheme.blueWhale,
      blendLevel: 10,
      fontFamily: GoogleFonts.notoSans().fontFamily,
    ).copyWith(
      scaffoldBackgroundColor: AppColors.background,
      cardColor: AppColors.surface,
    );
  }
}
