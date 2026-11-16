import 'package:auto_diary_ai/features/location/domain/entities/timeline_item.dart';
import 'package:auto_diary_ai/features/location/domain/entities/transport_mode.dart';
import 'package:auto_diary_ai/features/map/presentation/ui/widgets/timeline_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Stay stay(int h1, int m1, int h2, int m2, String name) => Stay(
  start: DateTime(2026, 10, 23, h1, m1),
  end: DateTime(2026, 10, 23, h2, m2),
  latitude: 35,
  longitude: 139,
  placeName: name,
  isPlaceNameEdited: true,
);

void main() {
  final items = <TimelineItem>[
    stay(0, 1, 7, 29, '自宅'),
    Move(
      start: DateTime(2026, 10, 23, 7, 29),
      end: DateTime(2026, 10, 23, 7, 56),
      distanceMeters: 7400,
      transport: TransportMode.bicycle,
    ),
    stay(7, 56, 17, 59, '職場'),
  ];

  Future<void> open(
    WidgetTester tester, {
    List<TimelineItem>? list,
    DateTime? selectedMoveStart,
  }) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);

    final controller = DraggableScrollableController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              TimelineSheet(
                controller: controller,
                date: DateTime(2026, 10, 23),
                canGoToPreviousDay: true,
                canGoToNextDay: true,
                onPreviousDay: () {},
                onNextDay: () {},
                onDateTap: () {},
                items: list ?? items,
                isLoading: false,
                placeCandidates: const {},
                selectedMoveStart: selectedMoveStart,
                onStayTap: (_) {},
                onMoveTap: (_) {},
                onPlaceNameChanged: (_, __, {registerPlace = false}) {},
                onTransportChanged: (_, __, ___) {},
                onRetryPlaceSearch: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // シートを大きく開いて、すべての行を出す
    controller.jumpTo(0.7);
    await tester.pumpAndSettle();
  }

  testWidgets('日付の切り替えが、年・月日・曜日に分けて出る', (tester) async {
    await open(tester);

    expect(find.text('2026年'), findsOneWidget);
    expect(find.text('10月23日'), findsOneWidget);
    expect(find.text('（金）'), findsOneWidget);
    expect(find.byTooltip('前の日'), findsOneWidget);
    expect(find.byTooltip('次の日'), findsOneWidget);
  });

  testWidgets('滞在には、番号と、滞在時間の札が出る。移動には番号が付かない', (tester) async {
    await open(tester);

    expect(find.text('自宅'), findsOneWidget);
    expect(find.text('00:01〜07:29'), findsOneWidget);
    expect(find.text('7時間28分'), findsOneWidget);
    expect(find.text('職場'), findsOneWidget);
    expect(find.text('10時間3分'), findsOneWidget);

    // 番号は、滞在だけに、上から1, 2
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsNothing);
  });

  testWidgets('番号の丸に、「1番目の滞在」のような読み上げ用の名前が付く', (tester) async {
    final semantics = tester.ensureSemantics();
    await open(tester);

    expect(find.bySemanticsLabel('1番目の滞在'), findsOneWidget);
    expect(find.bySemanticsLabel('2番目の滞在'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('移動は、名前と、距離・時刻・時間が、2行で出る', (tester) async {
    await open(tester);

    expect(find.text('自転車で移動（推定）'), findsOneWidget);
    expect(find.text('約7.4km ・ 07:29〜07:56（27分）'), findsOneWidget);
  });

  testWidgets('編集のボタンが、滞在と移動のそれぞれにある', (tester) async {
    await open(tester);

    expect(find.byTooltip('場所を編集'), findsNWidgets(2));
    expect(find.byTooltip('移動手段を編集'), findsOneWidget);
  });

  testWidgets('記録のない日は、案内が出る', (tester) async {
    await open(tester, list: const []);

    expect(find.text('この日の行動履歴はありません'), findsOneWidget);
  });
}
