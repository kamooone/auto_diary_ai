import 'package:auto_diary_ai/features/x_archive/application/services/x_archive_recall_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('通知の印に日付があれば、その日を取り出す', () {
    expect(
      XArchiveRecallNotifier.dateFromPayload('x_archive_recall:2026-11-12'),
      DateTime(2026, 11, 12),
    );
  });

  test('日付のない印(本番の通知)や、別の印は、nullになる', () {
    expect(XArchiveRecallNotifier.dateFromPayload('x_archive_recall'), isNull);
    expect(XArchiveRecallNotifier.dateFromPayload('other:2026-11-12'), isNull);
    expect(XArchiveRecallNotifier.dateFromPayload(null), isNull);
    expect(
      XArchiveRecallNotifier.dateFromPayload('x_archive_recall:not-a-date'),
      isNull,
    );
  });
}
