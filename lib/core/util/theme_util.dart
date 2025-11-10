import 'package:auto_diary_ai/core/constants/app_sizes.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ThemeUtil {
  static ThemeData homeTheme() {
    // FlexThemeData をベースに
    final baseTheme = FlexThemeData.light(
      scheme: FlexScheme.sanJuanBlue, // 基本色の設定
    );

    return baseTheme.copyWith(
      // Scaffold / 背景色
      scaffoldBackgroundColor: AppColors.background,
      // Card の色
      cardColor: AppColors.surface, // TODO: 動的に変更できるようにする
      // 全体のテキストテーマ
      textTheme: GoogleFonts.notoSansTextTheme(),

      // AppBar 専用のテーマ
      appBarTheme: AppBarTheme(
        backgroundColor: baseTheme.primaryColor, // FlexScheme に基づくプライマリカラー
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
