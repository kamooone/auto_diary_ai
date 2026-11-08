import 'package:flutter/material.dart';

/// Xの投稿の日時の表示と編集
class SharedPostFormat {
  SharedPostFormat._();

  static const _weekdays = ['月', '火', '水', '木', '金', '土', '日'];

  /// 「2026年1月1日（木）」の形
  static String date(DateTime date) {
    return "${date.year}年${date.month}月${date.day}日"
        "（${_weekdays[date.weekday - 1]}）";
  }

  /// 「09:05」の形
  static String time(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  /// 選んだ日付と時刻を合わせて、1つの日時にする(秒は0)
  static DateTime combine(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
}
