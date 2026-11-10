/// 過去のツイートの通知の設定
class XArchiveRecallSettings {
  final bool enabled;

  /// 通知する時刻(日本時間)
  final int hour;
  final int minute;

  const XArchiveRecallSettings({
    this.enabled = false,
    this.hour = defaultHour,
    this.minute = 0,
  });

  static const defaultHour = 20;

  XArchiveRecallSettings copyWith({bool? enabled, int? hour, int? minute}) {
    return XArchiveRecallSettings(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }
}
