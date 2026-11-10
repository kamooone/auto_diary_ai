import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// 過去のツイートを、毎日決まった時刻に知らせる端末内の通知
///
/// 通知の文言は固定。ツイートの内容は、通知をタップして開く画面で、その場で作る。
/// (「毎日この時刻」と1度予約すれば、アプリを開かなくても続く)
class XArchiveRecallNotifier {
  XArchiveRecallNotifier([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// 通知をタップしたときに渡す印
  static const payload = 'x_archive_recall';

  static const _notificationId = 7001;
  static const _channelId = 'x_archive_recall';

  static const title = '過去のあなたのツイート';
  static const body = '過去にこんなツイートをしていました。タップして見てみましょう';

  bool _initialized = false;

  /// 通知の準備。[onTap] は、通知をタップしたとき(アプリが動いている間)に呼ばれる
  Future<void> initialize({required ValueChanged<String?> onTap}) async {
    tzdata.initializeTimeZones();
    // 日付はすべて日本時間で扱うので、通知の時刻も日本時間にそろえる
    tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) => onTap(response.payload),
    );
    _initialized = true;
  }

  /// 通知をタップして、アプリが起動したときの印(そうでなければnull)
  Future<String?> launchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return null;
    return details?.notificationResponse?.payload;
  }

  /// 通知を出してよいか、許可を求める。許可されたらtrue
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    return await android.requestNotificationsPermission() ?? false;
  }

  /// 毎日 [hour]:[minute] (日本時間)に通知する。すでに予約があれば置き換える
  Future<void> schedule({required int hour, required int minute}) async {
    if (!_initialized) return;

    final now = tz.TZDateTime.now(tz.local);
    var first = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!first.isAfter(now)) first = first.add(const Duration(days: 1));

    await _plugin.zonedSchedule(
      _notificationId,
      title,
      body,
      first,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          '過去のツイート',
          channelDescription: '過去のツイートを、毎日お知らせします',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
      // 時刻は少しずれてもよい。正確なアラームの許可は使わない
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static const _testNotificationIdBase = 7100;

  /// 動作確認用:通知を、今すぐ [count] 件出す(見た目と、タップで画面が開くことを確かめる)
  Future<void> showTestNotifications({int count = 20}) async {
    if (!_initialized) return;

    for (var i = 1; i <= count; i++) {
      await _plugin.show(
        _testNotificationIdBase + i,
        '(テスト $i/$count) $title',
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            '過去のツイート',
            channelDescription: '過去のツイートを、毎日お知らせします',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: payload,
      );
    }
  }

  /// 予約した通知を取り消す
  Future<void> cancel() async {
    if (!_initialized) return;
    await _plugin.cancel(_notificationId);
  }
}
