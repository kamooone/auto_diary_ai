import 'package:auto_diary_ai/features/x_archive/application/providers/x_archive_recall_providers.dart';
import 'package:auto_diary_ai/features/x_archive/application/services/x_archive_recall_notifier.dart';
import 'package:auto_diary_ai/features/x_archive/data/repositories/x_archive_recall_settings_store.dart';
import 'package:auto_diary_ai/features/x_archive/domain/entities/x_archive_recall_settings.dart';
import 'package:auto_diary_ai/features/x_archive/presentation/ui/x_archive_recall_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Notifier extends XArchiveRecallNotifier {
  _Notifier({
    this.ready = true,
    this.permitted = true,
    this.scheduleFails = false,
  });

  final bool ready;
  final bool permitted;
  final bool scheduleFails;
  var scheduled = 0;
  var cancelled = 0;

  @override
  bool get isReady => ready;

  @override
  Future<bool> requestPermission() async => permitted;

  @override
  Future<void> schedule({required int hour, required int minute}) async {
    if (scheduleFails) throw StateError('failed');
    scheduled++;
  }

  @override
  Future<void> cancel() async => cancelled++;
}

class _Store implements XArchiveRecallSettingsStore {
  var settings = const XArchiveRecallSettings();

  @override
  Future<XArchiveRecallSettings> load() async => settings;

  @override
  Future<void> save(XArchiveRecallSettings value) async => settings = value;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Future<({_Notifier notifier, _Store store})> open(
    WidgetTester tester, {
    bool available = true,
    _Notifier? notifier,
  }) async {
    final fakeNotifier = notifier ?? _Notifier();
    final store = _Store();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          xArchiveRecallNotifierProvider.overrideWithValue(fakeNotifier),
          xArchiveRecallSettingsStoreProvider.overrideWithValue(store),
          xArchiveRecallAvailableProvider.overrideWith(
            (ref) async => available,
          ),
        ],
        child: const MaterialApp(home: XArchiveRecallSettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    return (notifier: fakeNotifier, store: store);
  }

  testWidgets('Xのアーカイブを取り込んでいないと、理由と、取り込むボタンを出し、スイッチは押せない', (tester) async {
    await open(tester, available: false);

    expect(find.textContaining('まだ、Xのアーカイブを取り込んでいないため'), findsOneWidget);
    expect(find.text('Xのアーカイブを取り込む'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
  });

  testWidgets('取り込み済みなら、案内は出さず、スイッチをオンにすると、保存して、通知を予約する', (tester) async {
    final result = await open(tester);

    expect(find.textContaining('まだ、Xのアーカイブを取り込んでいないため'), findsNothing);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(result.store.settings.enabled, isTrue);
    expect(result.notifier.scheduled, 1);
  });

  testWidgets('通知が許可されなかったときは、オンにせず、設定を開く操作を出す', (tester) async {
    final result = await open(tester, notifier: _Notifier(permitted: false));

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.textContaining('通知が許可されていません'), findsOneWidget);
    expect(find.text('設定を開く'), findsOneWidget);
    expect(result.store.settings.enabled, isFalse);
    expect(result.notifier.scheduled, 0);
  });

  testWidgets('通知の準備ができていないときは、オンにせず、理由を知らせる', (tester) async {
    final result = await open(tester, notifier: _Notifier(ready: false));

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.textContaining('通知を準備できていません'), findsOneWidget);
    expect(result.store.settings.enabled, isFalse);
  });

  testWidgets('予約に失敗したときは、オンにせず、理由を知らせる', (tester) async {
    final result = await open(tester, notifier: _Notifier(scheduleFails: true));

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.textContaining('通知を設定できませんでした'), findsOneWidget);
    expect(result.store.settings.enabled, isFalse);
  });
}
