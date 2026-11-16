import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:auto_diary_ai/common/constants/app_colors.dart';
import 'package:auto_diary_ai/common/constants/app_sizes.dart';

class ThemeUtil {
  /// [useGoogleFonts]をfalseにすると、フォントをネットから読まず、[fontFamily]を使う
  /// (画面を画像にして確かめるテスト用)
  static ThemeData appTheme({bool useGoogleFonts = true, String? fontFamily}) {
    final base = FlexThemeData.light(scheme: FlexScheme.sanJuanBlue);

    final colorScheme = base.colorScheme.copyWith(
      primary: AppColors.navy,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.pink,
      onPrimaryContainer: AppColors.navyDark,
      surface: AppColors.white,
      onSurface: AppColors.text,
    );

    final textTheme =
        (useGoogleFonts
                ? GoogleFonts.notoSansTextTheme()
                : base.textTheme.apply(fontFamily: fontFamily))
            .apply(bodyColor: AppColors.text, displayColor: AppColors.text);

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.pageBackground,
      cardColor: AppColors.white,
      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: useGoogleFonts
            ? GoogleFonts.notoSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.72,
                color: AppColors.white,
              )
            : TextStyle(
                fontFamily: fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.72,
                color: AppColors.white,
              ),
        iconTheme: const IconThemeData(color: AppColors.white),
        actionsIconTheme: const IconThemeData(color: AppColors.white),
      ),

      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 1,
        shadowColor: AppColors.navyDark.withValues(alpha: 0.25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius16),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius16),
        ),
      ),

      // 入力欄・選択欄: 白い面に、うすい枠(選んでいるときは、ネイビー)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: _inputBorder(AppColors.line),
        enabledBorder: _inputBorder(AppColors.line),
        focusedBorder: _inputBorder(AppColors.navy, width: 1.5),
        disabledBorder: _inputBorder(AppColors.line),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.pageBackground,
        modalBarrierColor: AppColors.scrim,
      ),

      // 下のメニュー: 白い帯。選んでいるものは、淡いピンクの印と、ネイビーの色
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.pink,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.navy
                : AppColors.textSub,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: states.contains(WidgetState.selected)
                ? AppColors.navy
                : AppColors.textSub,
          ),
        ),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radius12),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
