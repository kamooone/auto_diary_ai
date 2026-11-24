// 様々な端末(画面の大きさ・向き・文字の大きさ)で、主な画面が、はみ出さないかを確かめる
//
// 端末の画面サイズと、端末の設定の「フォントサイズ」を、いろいろ変えて、画面を作り、
// 「RenderFlex overflowed」(はみ出し)などの描画のエラーが出ないかを調べる。
// 広告(バナー)の分の高さは、画面の高さから引いて、まねる。
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:auto_diary_ai/app/theme/theme_util.dart';
import 'package:auto_diary_ai/common/widgets/month_bar.dart';
import 'package:auto_diary_ai/features/ads/application/ads_provider.dart';
import 'package:auto_diary_ai/features/calendar/presentation/ui/calendar_screen.dart';
import 'package:auto_diary_ai/features/diary/application/providers/diary_providers.dart';
import 'package:auto_diary_ai/features/diary/domain/entities/diary.dart';
import 'package:auto_diary_ai/features/diary_create/application/providers/diary_usecase_providers.dart';
import 'package:auto_diary_ai/features/diary_create/domain/entities/photo.dart';
import 'package:auto_diary_ai/features/diary_create/domain/usecases/get_photo_thumbnail_usecase.dart';
import 'package:auto_diary_ai/features/diary_create/presentation/ui/diary_ai_screen.dart';
import 'package:auto_diary_ai/features/diary_create/presentation/ui/diary_create_screen.dart';
import 'package:auto_diary_ai/features/diary_create/presentation/ui/summary_diary_screen.dart';
import 'package:auto_diary_ai/features/home/domain/services/timeline_entries.dart';
import 'package:auto_diary_ai/features/home/presentation/ui/widgets/diary_timeline_view.dart';
import 'package:auto_diary_ai/features/home/presentation/ui/widgets/home_fab.dart';
import 'package:auto_diary_ai/features/home/presentation/ui/widgets/home_scaffold.dart';
import 'package:auto_diary_ai/features/inquiry/application/providers/inquiry_providers.dart';
import 'package:auto_diary_ai/features/inquiry/presentation/ui/inquiry_page.dart';
import 'package:auto_diary_ai/features/location/application/providers/location_providers.dart';
import 'package:auto_diary_ai/features/location/domain/entities/timeline_item.dart';
import 'package:auto_diary_ai/features/location/domain/usecases/get_timeline_by_date_usecase.dart';
import 'package:auto_diary_ai/features/memo/application/providers/memo_providers.dart';
import 'package:auto_diary_ai/features/memo/domain/entities/memo.dart';
import 'package:auto_diary_ai/features/memo/domain/repositories/memo_repository.dart';
import 'package:auto_diary_ai/features/memo/presentation/ui/memo_list_view.dart';
import 'package:auto_diary_ai/features/plan/application/providers/plan_provider.dart';
import 'package:auto_diary_ai/features/plan/domain/entities/plan_type.dart';
import 'package:auto_diary_ai/features/plan/domain/entities/usage_info.dart';
import 'package:auto_diary_ai/features/plan/domain/repositories/plan_repository.dart';
import 'package:auto_diary_ai/features/plan/domain/repositories/usage_repository.dart';
import 'package:auto_diary_ai/features/plan/presentation/ui/plan_page.dart';
import 'package:auto_diary_ai/features/points/application/providers/device_link_provider.dart';
import 'package:auto_diary_ai/features/points/application/providers/pairing_provider.dart';
import 'package:auto_diary_ai/features/points/domain/entities/pairing_session.dart';
import 'package:auto_diary_ai/features/points/domain/repositories/device_token_store.dart';
import 'package:auto_diary_ai/features/points/domain/repositories/pairing_repository.dart';
import 'package:auto_diary_ai/features/points/presentation/ui/points_guide_page.dart';
import 'package:auto_diary_ai/features/points/presentation/ui/points_page.dart';
import 'package:auto_diary_ai/features/privacy/presentation/ui/privacy_policy_page.dart';
import 'package:auto_diary_ai/features/share/application/providers/share_providers.dart';
import 'package:auto_diary_ai/features/share/domain/entities/shared_post.dart';
import 'package:auto_diary_ai/features/share/domain/usecases/get_shared_posts_usecase.dart';
import 'package:auto_diary_ai/features/tutorial/application/tutorial_providers.dart';
import 'package:auto_diary_ai/features/tutorial/data/tutorial_seen_store.dart';
import 'package:auto_diary_ai/features/x_archive/application/providers/x_archive_providers.dart';
import 'package:auto_diary_ai/features/x_archive/application/providers/x_archive_recall_providers.dart';
import 'package:auto_diary_ai/features/x_archive/domain/entities/x_archive_post.dart';
import 'package:auto_diary_ai/features/x_archive/domain/entities/x_archive_recall.dart';
import 'package:auto_diary_ai/features/x_archive/presentation/ui/x_archive_recall_page.dart';
import 'package:auto_diary_ai/core/app_info/app_version_provider.dart';
import 'package:auto_diary_ai/features/setting/presentation/providers/recording_settings_provider.dart';
import 'package:auto_diary_ai/features/setting/presentation/ui/settings_page.dart';
import 'package:auto_diary_ai/features/share/presentation/ui/shared_post_list_screen.dart';
import 'package:auto_diary_ai/features/x_archive/domain/entities/x_archive_recall_settings.dart';
import 'package:auto_diary_ai/features/x_archive/presentation/ui/x_archive_recall_settings_page.dart';
import 'package:auto_diary_ai/features/x_archive/presentation/ui/x_archive_post_list_page.dart';
import 'package:auto_diary_ai/features/x_archive/presentation/ui/x_archive_import_page.dart';
import '../features/x_archive/fake_x_archive_repository.dart';
import 'package:auto_diary_ai/common/widgets/confirm_dialog.dart';
import 'package:auto_diary_ai/features/diary_create/presentation/ui/widgets/token_shortage_dialog.dart';
import 'package:auto_diary_ai/features/location/domain/entities/transport_mode.dart';
import 'package:auto_diary_ai/features/location/presentation/ui/activity_permission_explanation.dart';
import 'package:auto_diary_ai/features/map/presentation/ui/widgets/timeline_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/inquiry/inquiry_test.dart'
    show
        FakeInquiryRepository,
        FakePushGateway,
        FakePushTokens,
        MemoryStateStore;

// ---------- 確かめる端末(単位は、論理ピクセル(dp))

class Device {
  const Device(this.name, this.width, this.height);

  final String name;
  final double width;
  final double height;
}

const devices = [
  Device('小さい端末(320x568)', 320, 568),
  Device('小型(360x640)', 360, 640),
  Device('標準(360x800)', 360, 800),
  Device('大きめ(412x915)', 412, 915),
  Device('折りたたみの外画面(280x653)', 280, 653),
  Device('タブレット縦(600x960)', 600, 960),
  Device('タブレット大(800x1280)', 800, 1280),
  Device('横向きの携帯(800x360)', 800, 360),
];

/// 端末の「フォントサイズ」の設定の倍率(Androidは、最大2.0まで選べる)
const textScales = [1.0, 1.3, 1.5, 2.0];

/// バナー広告の高さ + 余白(広告を無効にしたテストの高さから、引いて、広告の分をまねる)
const adHeight = 60.0;

// ---------- 画面の用意

class _Thumb implements GetPhotoThumbnailUseCase {
  @override
  Future<Uint8List?> execute(Photo photo) async => base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAgAAAAIAQMAAAD+wSzIAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAAGUExURZ+wzP///2W1YuEAAAABYktHRAH/Ai3eAAAAB3RJTUUH6gsQASsELB2njQAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyNi0xMS0xNlQwMTo0MzowNCswMDowMGroENwAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjYtMTEtMTZUMDE6NDM6MDQrMDA6MDAbtahgAAAAKHRFWHRkYXRlOnRpbWVzdGFtcAAyMDI2LTExLTE2VDAxOjQzOjA0KzAwOjAwTKCJvwAAAAtJREFUCNdjYEAFAAAQAAGhxSHBAAAAAElFTkSuQmCC',
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Seen implements TutorialSeenStore {
  @override
  Future<bool> hasSeen(String id) async => true;

  @override
  Future<void> markSeen(String id) async {}

  @override
  Future<void> clearAll() async {}
}

class _Usage implements UsageRepository {
  @override
  Future<UsageInfo?> fetch({PlanType plan = PlanType.free}) async => UsageInfo(
    plan: PlanType.free,
    usedTokens: 4200,
    limitTokens: 10000,
    resetsAt: DateTime(2026, 12, 1),
    tokenBalance: 16597000,
  );
}

class _Plan implements PlanRepository {
  @override
  Future<PlanType> load() async => PlanType.free;

  @override
  Future<void> save(PlanType plan) async {}
}

class _Timeline implements GetTimelineByDateUseCase {
  @override
  Future<List<TimelineItem>> execute(
    DateTime date, {
    bool estimatePlaces = true,
  }) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Posts implements GetSharedPostsUseCase {
  @override
  Future<List<SharedPost>> execute(DateTime date) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Memos implements MemoRepository {
  @override
  Future<List<Memo>> findBetween(DateTime start, DateTime end) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Store implements DeviceTokenStore {
  _Store({this.token});

  final String? token;

  @override
  Future<String?> load() async => token;

  @override
  Future<void> save(String token) async {}

  @override
  Future<void> clear() async {}
}

class _Pairing implements PairingRepository {
  @override
  Future<PairingSession> start({required String label}) async => PairingSession(
    code: '899026',
    claimSecret: 'secret',
    expiresAt: DateTime.now().add(const Duration(minutes: 10)),
  );

  @override
  Future<void> unlink(String deviceToken) async {}

  @override
  Future<PairingClaimResult> claim(PairingSession session) async =>
      const PairingPending();
}

class _Recording extends RecordingSettingsNotifier {
  @override
  Future<RecordingSettingsState> build() async => const RecordingSettingsState(
    isSupported: true,
    isEnabled: true,
    isWidgetPinSupported: true,
    isWidgetPinned: false,
  );
}

List<XArchivePost> _archivePosts() => [
  for (var i = 0; i < 30; i++)
    XArchivePost(
      tweetId: 'p$i',
      text: '取り込んだ投稿その$i。少し長めの文章が入っている場合の見え方を確かめます。',
      createdAt: DateTime.utc(2024, 1 + i % 12, 1 + i % 28, 3),
      kind: XArchivePostKind.post,
    ),
];

Diary _diary(
  int day,
  String title, {
  int hour = 9,
  bool ai = false,
  bool photo = false,
}) {
  final now = DateTime.now();
  return Diary(
    date: DateTime(now.year, now.month, day, hour),
    title: title,
    content: '',
    isAiGenerated: ai,
    photoIds: photo ? const ['p'] : const [],
    createdAt: DateTime(now.year, now.month, day, hour),
  );
}

List<Diary> _diaries() => [
  _diary(1, '次の企画の準備'),
  _diary(3, '運動と料理の一日と、とても長いタイトルの日記が入っている場合'),
  _diary(5, '料理教室の発表会', ai: true),
  _diary(9, '計画づくり', photo: true),
  _diary(11, '10キロのレースを走り切った'),
  _diary(14, '遠足に行った', photo: true),
  _diary(14, '夜の記録', hour: 21),
  _diary(15, '母が上京してきた'),
];

final _overrides = <Override>[
  adsEnabledProvider.overrideWithValue(false),
  getPhotoThumbnailUseCaseProvider.overrideWithValue(_Thumb()),
  tutorialSeenStoreProvider.overrideWithValue(_Seen()),
  usageRepositoryProvider.overrideWithValue(_Usage()),
  planRepositoryProvider.overrideWithValue(_Plan()),
  getTimelineByDateUseCaseProvider.overrideWithValue(_Timeline()),
  getSharedPostsUseCaseProvider.overrideWithValue(_Posts()),
  memoRepositoryProvider.overrideWithValue(_Memos()),
  diariesProvider.overrideWith((ref) => Stream.value(_diaries())),
  pairingRepositoryProvider.overrideWithValue(_Pairing()),
  pairingPollIntervalProvider.overrideWithValue(const Duration(minutes: 5)),
  pairingLabelProvider.overrideWithValue('テスト端末'),
];

Widget _app(Widget home, {List<Override> extra = const []}) {
  return ProviderScope(
    overrides: [..._overrides, ...extra],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeUtil.appTheme(useGoogleFonts: false, fontFamily: _font),
      home: home,
    ),
  );
}

/// 日本語を、実際の幅で描ける字体(なければ、テスト用の四角の字体になる)
String? _font;

Future<void> _loadFont() async {
  const path = '/Library/Fonts/Arial Unicode.ttf';
  if (!File(path).existsSync()) return;

  final bytes = File(path).readAsBytesSync();
  final loader = FontLoader('TestJP')
    ..addFont(Future.value(ByteData.view(bytes.buffer)));
  await loader.load();
  _font = 'TestJP';
}

// ---------- 画面の一覧

class Screen {
  const Screen(this.name, this.build, {this.after});

  final String name;
  final Widget Function() build;

  /// 画面を作ったあとに、行う操作(シートを開く、ダイアログを出す、など)
  final Future<void> Function(WidgetTester tester)? after;
}

/// 画面の上に、ダイアログを出す
Future<void> _showOver(
  WidgetTester tester,
  Future<Object?> Function(BuildContext context) show,
) async {
  final context = tester.element(find.byType(Scaffold).first);
  unawaited(show(context));
  await tester.pump(const Duration(milliseconds: 400));
}

Screen _dialog(
  String name,
  Future<Object?> Function(BuildContext context) show,
) {
  return Screen(
    name,
    () => _app(const Scaffold(body: SizedBox.expand())),
    after: (tester) => _showOver(tester, show),
  );
}

late DraggableScrollableController _sheetController;

Widget _timelineSheet() {
  _sheetController = DraggableScrollableController();
  Stay stay(
    int h1,
    int h2,
    String name, {
    bool edited = true,
    String? estimated,
  }) => Stay(
    start: DateTime(2026, 10, 23, h1, 5),
    end: DateTime(2026, 10, 23, h2, 40),
    latitude: 35,
    longitude: 139,
    placeName: name,
    estimatedPlaceName: estimated,
    isPlaceNameEdited: edited,
  );
  final items = <TimelineItem>[
    stay(0, 7, '自宅'),
    Move(
      start: DateTime(2026, 10, 23, 7, 40),
      end: DateTime(2026, 10, 23, 8, 5),
      distanceMeters: 12400,
      transport: TransportMode.bicycle,
      transportText: '友人の車で、高速道路を使って、遠くの実家まで移動した',
      isTransportEdited: true,
    ),
    stay(
      8,
      17,
      'とても長い名前の店舗(東京駅前・丸の内中央口・地下1階の改札外)',
      edited: false,
      estimated: '東京都千代田区丸の内一丁目9番1号の、とても長い住所の施設',
    ),
    RecordingOff(
      start: DateTime(2026, 10, 23, 18, 0),
      end: DateTime(2026, 10, 23, 20, 30),
    ),
  ];

  return _app(
    Scaffold(
      body: Stack(
        children: [
          TimelineSheet(
            controller: _sheetController,
            date: DateTime(2026, 10, 23),
            canGoToPreviousDay: true,
            canGoToNextDay: true,
            onPreviousDay: () {},
            onNextDay: () {},
            onDateTap: () {},
            items: items,
            isLoading: false,
            placeCandidates: const {},
            selectedMoveStart: null,
            onStayTap: (_) {},
            onMoveTap: (_) {},
            onPlaceNameChanged: (_, __, {registerPlace = false}) {},
            onTransportChanged: (_, __, ___) {},
            onRetryPlaceSearch: () {},
            onDelete: (_) {},
          ),
        ],
      ),
    ),
  );
}

Widget _home() {
  final items = _diaries();
  const month = '2026-10';
  return _app(
    HomeScaffold(
      title: 'あなたの軌跡',
      actions: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.calendar_month)),
        IconButton(onPressed: () {}, icon: const Icon(Icons.map_outlined)),
        IconButton(onPressed: () {}, icon: const Icon(Icons.menu)),
      ],
      body: Stack(
        children: [
          Column(
            children: [
              MonthBar(
                months: const ['2026-10', '2026-03'],
                selectedMonth: month,
                recordedDays: countRecordedDays(items),
                onChanged: (_) {},
              ),
              Expanded(
                child: DiaryTimelineView(
                  months: const [month],
                  itemsPerMonth: {month: items},
                  pageController: PageController(),
                  onPageChanged: (_) {},
                ),
              ),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: HomeFab(
              heroTag: 'x',
              tooltip: 't',
              label: '日記を書く',
              onPressed: () {},
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            label: '日記',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            label: 'ひとこと',
          ),
        ],
      ),
    ),
  );
}

final inquiryOverrides = <Override>[
  inquiryRepositoryProvider.overrideWithValue(FakeInquiryRepository()),
  inquiryStateStoreProvider.overrideWithValue(MemoryStateStore()),
  pushMessagingGatewayProvider.overrideWithValue(FakePushGateway()),
  pushTokenRepositoryProvider.overrideWithValue(FakePushTokens()),
];

final screens = <Screen>[
  Screen('ホーム', _home),
  Screen('カレンダー', () => _app(const CalendarScreen())),
  Screen(
    'ひとこと一覧',
    () => _app(
      Scaffold(
        appBar: AppBar(title: const Text('あなたの軌跡')),
        body: const MemoListView(),
      ),
      extra: [
        allMemosProvider.overrideWith(
          (ref) async => [
            Memo(
              text: '駅前のカフェで、ゆっくり本を読んだ。',
              createdAt: DateTime(2026, 11, 16, 14, 20),
            ),
            Memo(text: '朝のコーヒー', createdAt: DateTime(2026, 11, 15, 8, 30)),
            Memo(
              text: '打ち合わせが長引いた。帰りに、少しだけ遠回りをして帰った。夕方の空がきれいだった。',
              createdAt: DateTime(2026, 10, 30, 19, 0),
            ),
          ],
        ),
      ],
    ),
  ),
  Screen('日記の作成', () => _app(const DiaryCreateScreen())),
  Screen('AIで日記', () => _app(const DiaryAiScreen())),
  Screen('まとめ日記', () => _app(const SummaryDiaryScreen())),
  Screen(
    'ポイント・ゲーム(未紐づけ)',
    () => _app(
      const PointsPage(),
      extra: [deviceTokenStoreProvider.overrideWithValue(_Store())],
    ),
  ),
  Screen(
    'ポイント・ゲーム(紐づけ済み)',
    () => _app(
      const PointsPage(),
      extra: [deviceTokenStoreProvider.overrideWithValue(_Store(token: 'a.b'))],
    ),
  ),
  Screen('ポイントの使い方', () => _app(const PointsGuidePage())),
  Screen(
    'AIの使用量(プラン)',
    () => _app(
      const PlanPage(),
      extra: [deviceTokenStoreProvider.overrideWithValue(_Store(token: 'a.b'))],
    ),
  ),
  Screen('プライバシーポリシー', () => _app(const PrivacyPolicyPage())),
  Screen(
    'お問い合わせ',
    () => _app(
      const InquiryPage(),
      extra: [
        inquiryRepositoryProvider.overrideWithValue(FakeInquiryRepository()),
        inquiryStateStoreProvider.overrideWithValue(MemoryStateStore()),
        pushMessagingGatewayProvider.overrideWithValue(FakePushGateway()),
        pushTokenRepositoryProvider.overrideWithValue(FakePushTokens()),
      ],
    ),
  ),
  Screen(
    '過去のポスト(通知から開く画面)',
    () => _app(
      const XArchiveRecallPage(),
      extra: [
        xArchiveRecallProvider.overrideWith(
          (ref, date) async => XArchiveRecall(
            years: [
              XArchiveRecallYear(
                yearsAgo: 1,
                date: DateTime(2025, 12, 6),
                posts: [
                  XArchivePost(
                    tweetId: 'a',
                    text: '一年前の投稿です。少し長めの文章が入っている場合の見え方を確かめます。',
                    createdAt: DateTime.utc(2025, 12, 7, 3),
                    kind: XArchivePostKind.post,
                  ),
                ],
              ),
            ],
            randoms: [
              XArchivePost(
                tweetId: 'b',
                text: 'ランダムな投稿',
                createdAt: DateTime.utc(2023, 4, 1, 3),
                kind: XArchivePostKind.post,
              ),
            ],
          ),
        ),
      ],
    ),
  ),
  Screen(
    '設定',
    () => _app(
      const SettingsPage(),
      extra: [
        recordingSettingsProvider.overrideWith(_Recording.new),
        appVersionProvider.overrideWith((ref) async => '1.0.0 (187)'),
        hasUnreadReplyProvider.overrideWith((ref) async => true),
        deviceTokenStoreProvider.overrideWithValue(_Store(token: 'a.b')),
      ],
    ),
  ),
  Screen(
    'Xの投稿一覧',
    () => _app(
      const SharedPostListScreen(),
      extra: [
        allSharedPostsProvider.overrideWith(
          (ref) async => [
            for (var i = 0; i < 8; i++)
              SharedPost(
                id: i,
                url: 'https://x.com/a/status/$i',
                text: '共有したXの投稿その$i。少し長めの文章が入っている場合の見え方を確かめます。',
                receivedAt: DateTime(2026, 10, 1 + i, 12),
              ),
          ],
        ),
      ],
    ),
  ),
  Screen(
    '取り込んだXの投稿一覧',
    () => _app(
      const XArchivePostListPage(),
      extra: [
        xArchiveRepositoryProvider.overrideWithValue(
          FakeXArchiveRepository(_archivePosts()),
        ),
      ],
    ),
  ),
  Screen(
    'Xのアーカイブを取り込む',
    () => _app(
      const XArchiveImportPage(),
      extra: [
        xArchiveRepositoryProvider.overrideWithValue(
          FakeXArchiveRepository(_archivePosts()),
        ),
      ],
    ),
  ),
  Screen(
    '過去のポストの通知(設定の画面)',
    () => _app(
      const XArchiveRecallSettingsPage(),
      extra: [
        xArchiveRecallSettingsProvider.overrideWith(
          (ref) async => const XArchiveRecallSettings(enabled: true),
        ),
        xArchiveRecallAvailableProvider.overrideWith((ref) async => true),
      ],
    ),
  ),
  Screen(
    '行動履歴のシート(マップ画面)',
    _timelineSheet,
    after: (tester) async {
      await tester.pump(const Duration(milliseconds: 300));
      _sheetController.jumpTo(0.9);
      await tester.pump(const Duration(milliseconds: 300));
    },
  ),
  _dialog(
    'ダイアログ: トークンが足りない見込み',
    (context) => showTokenShortageDialog(
      context,
      estimated: 12345,
      remaining: 1234,
      photoTokens: 1100,
    ),
  ),
  _dialog('ダイアログ: 身体活動の説明', showActivityPermissionExplanation),
  _dialog(
    'ダイアログ: 確認(長い文)',
    (context) => showConfirmDialog(
      context,
      icon: Icons.delete_outline,
      title: 'この滞在を削除しますか?',
      message: 'その時間帯の位置情報のデータも、端末から削除されます。元に戻せません。確認のため、少し長めの文章を入れています。',
      confirmLabel: '削除する',
    ),
  ),
];

// ---------- 確かめる処理

/// [screen]を、[device]の画面で、文字を[scale]倍にして描き、描画のエラーを集める
Future<List<String>> _render(
  WidgetTester tester,
  Screen screen,
  Device device,
  double scale,
) async {
  final errors = <String>[];
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    final lines = details.toString().split('\n');
    // はみ出した部品の場所も、一緒に出す(どこを直せばよいか分かるように)
    final at = lines.indexWhere((l) => l.contains('error-causing widget'));
    final where = at >= 0 && at + 2 < lines.length
        ? ' → ${lines[at + 1].trim()} ${lines[at + 2].trim()}'
        : '';
    final text = '${details.exceptionAsString().split('\n').first}$where';
    if (!errors.contains(text)) errors.add(text);
  };

  try {
    const ratio = 2.0;
    final height = (device.height - adHeight).clamp(200.0, 4000.0);
    tester.view.devicePixelRatio = ratio;
    tester.view.physicalSize = Size(device.width * ratio, height * ratio);
    tester.platformDispatcher.textScaleFactorTestValue = scale;

    await tester.pumpWidget(screen.build());
    // 非同期の読み込みを待つ(終わらないアニメーションがあっても、止まらないようにする)
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    final after = screen.after;
    if (after != null) await after(tester);
  } finally {
    FlutterError.onError = original;
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    tester.view.reset();
  }

  return errors;
}

void main() {
  setUpAll(_loadFont);

  for (final screen in screens) {
    testWidgets('${screen.name}は、どの端末・文字の大きさでも、はみ出さない', (tester) async {
      final problems = <String>[];

      for (final device in devices) {
        for (final scale in textScales) {
          final errors = await _render(tester, screen, device, scale);
          for (final error in errors) {
            problems.add('${device.name} 文字×$scale: $error');
          }
        }
      }

      if (problems.isNotEmpty) {
        debugPrint('【${screen.name}】\n${problems.join('\n')}');
      }
      expect(problems, isEmpty, reason: screen.name);
    });
  }
}
