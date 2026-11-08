import 'package:flutter_riverpod/flutter_riverpod.dart';

// 月選択を管理するNotifier
class SelectedMonthNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setMonth(String month) {
    state = month;
  }
}

// NotifierProvider
final selectedMonthProvider = NotifierProvider<SelectedMonthNotifier, String>(SelectedMonthNotifier.new);
