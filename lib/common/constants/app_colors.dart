import 'package:flutter/material.dart';

/// 「あなたの軌跡」の色のルール（ホーム画面ブラッシュアップ版）
///
/// オレンジは「今日・いちばん新しい記録・日記を書くボタン」だけに使う。
/// ほかの画面でも、このルールを守る(色がぶれないようにするため)。
class AppColors {
  AppColors._();

  // ---- 基本の色 ----
  /// ネイビー：ヘッダー、日付、アイコン、タイムラインの印、表示中の月
  static const navy = Color(0xFF3F5879);

  /// ネイビー（濃）：強調したい数字や文字（日付の数字、件数など）
  static const navyDark = Color(0xFF2E4260);

  /// 淡いピンク：下のメニューで選択中の印、やわらかい面
  static const pink = Color(0xFFFFE4E1);

  /// 画面の背景（ピンクをさらに薄くした色）：すべての画面とシートの背景
  static const pageBackground = Color(0xFFFFF7F5);

  /// ホワイト：カード、ボタン、下のメニュー、広告の帯
  static const white = Color(0xFFFFFFFF);

  /// オレンジ：今日・いちばん新しい記録の印、今月の枠
  static const orange = Color(0xFFE06A2E);

  /// オレンジ（濃）：「日記を書く」など押せるボタンの塗り（白文字が読める濃さ）
  static const orangeDark = Color(0xFFC75A22);

  // ---- 文字と線 ----
  /// 文字：タイトル、本文
  static const text = Color(0xFF1F2430);

  /// 補助の文字：曜日（平日）、説明、件数、「10月のはじまり」
  static const textSub = Color(0xFF5E6472);

  /// 線：区切り線、白いボタンや月ボタンの枠
  static const line = Color(0xFFF0DAD5);

  /// タイムラインの点線と、終わりの小さな点
  static const timelineDots = Color(0xFFEDC3B8);

  /// カードの右の矢印（›）
  static const chevron = Color(0xFFA9AEB8);

  // ---- 曜日 ----
  static const saturday = Color(0xFF3A5A96);
  static const sunday = Color(0xFFB4442B);

  // ---- 影・重ね ----
  /// カードの影（1種類だけ）：
  /// BoxShadow(color: cardShadow1, blurRadius: 2, offset: Offset(0, 1)),
  /// BoxShadow(color: cardShadow2, blurRadius: 8, offset: Offset(0, 2))
  static const cardShadow1 = Color(0x0F2E4260); // 6%
  static const cardShadow2 = Color(0x0D2E4260); // 5%

  /// 「日記を書く」ボタンの影：blurRadius 12, offset (0, 4)
  static const fabShadow = Color(0x47C75A22); // 28%

  /// いちばん新しい記録の印のまわりの淡い輪（印の外側4px）
  static const latestDotRing = Color(0x29E06A2E); // 16%

  /// 年月シートを出したときの、うしろの画面を暗くする色
  static const scrim = Color(0x6B1F2430); // 42%

  /// 年月シートの上のつまみ
  static const sheetHandle = Color(0xFFD9C9C5);

  /// カードの影(2つを重ねて、1種類の影にする)
  static const cardShadows = [
    BoxShadow(color: cardShadow1, blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: cardShadow2, blurRadius: 8, offset: Offset(0, 2)),
  ];
}
