import 'package:flutter/material.dart';
import '../../../../../common/constants/app_colors.dart';
import '../../../../../common/constants/app_sizes.dart';
import '../../../../../common/widgets/month_bar.dart' show RoundNavButton;
import '../../../../location/domain/entities/place_candidate.dart';
import '../../../../location/domain/entities/timeline_item.dart';
import '../../../../location/domain/entities/transport_mode.dart';
import '../../../../location/presentation/formatters/timeline_formatter.dart';

/// 1日の行動(滞在した場所と移動)を時系列で表示するシート
class TimelineSheet extends StatelessWidget {
  const TimelineSheet({
    super.key,
    required this.controller,
    required this.date,
    required this.canGoToPreviousDay,
    required this.canGoToNextDay,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.onDateTap,
    required this.items,
    required this.isLoading,
    required this.placeCandidates,
    required this.selectedMoveStart,
    required this.onStayTap,
    required this.onMoveTap,
    required this.onPlaceNameChanged,
    required this.onTransportChanged,
    required this.onRetryPlaceSearch,
    this.sheetKey,
  });

  /// シートを最も小さくしたときの高さ(画面に対する割合)
  /// 日付の切り替えが隠れない高さにする
  static const minSize = 0.13;

  /// シートの高さを外から操作するためのコントローラ
  final DraggableScrollableController controller;

  /// 表示している日
  final DateTime date;

  /// 前日・翌日へ切り替えられるかどうか(記録のある範囲の端では切り替えられない)
  final bool canGoToPreviousDay;
  final bool canGoToNextDay;

  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;

  /// 日付をタップしたとき(カレンダーから日付を選ぶ)
  final VoidCallback onDateTap;

  final List<TimelineItem> items;

  /// 地名や訪れた場所を取得中かどうか
  final bool isLoading;

  /// 滞在の開始時刻ごとの、周辺の施設の候補
  final Map<DateTime, List<PlaceCandidate>> placeCandidates;

  /// 選択中の移動の開始時刻(選択していない場合はnull)
  final DateTime? selectedMoveStart;

  final ValueChanged<Stay> onStayTap;

  /// 移動をタップしたとき(地図に移動経路を表示する)
  final ValueChanged<Move> onMoveTap;

  /// 場所名がnullの場合は、自動で取得した場所名に戻す
  ///
  /// [registerPlace]がtrueの場合は、次回以降もこの場所の名前として表示する
  final void Function(Stay stay, String? placeName, {bool registerPlace})
  onPlaceNameChanged;

  /// 移動手段と、移動の説明(自由に書いた文)
  /// どちらもnullの場合は、自動推定に戻す
  final void Function(Move move, TransportMode? transport, String? text)
  onTransportChanged;

  /// 取得できなかった訪れた場所を、もう一度取得する
  final VoidCallback onRetryPlaceSearch;

  /// シート全体の目印(チュートリアルで明るくするため)
  final GlobalKey? sheetKey;

  @override
  Widget build(BuildContext context) {
    // 滞在には、上から1, 2, 3…と番号を付ける(移動と、記録のない時間には付けない)
    final stayNumbers = <int, int>{};
    var count = 0;
    for (var i = 0; i < items.length; i++) {
      if (items[i] is Stay) stayNumbers[i] = ++count;
    }

    return DraggableScrollableSheet(
      controller: controller,
      initialChildSize: 0.25,
      minChildSize: minSize,
      maxChildSize: 0.7,
      builder: (context, scrollController) {
        return Container(
          key: sheetKey,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.pageBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            // 左右にスワイプすると、ページをめくるように翌日・前日へ切り替える
            child: _DaySwipePager(
              canGoToPreviousDay: canGoToPreviousDay,
              canGoToNextDay: canGoToNextDay,
              onPreviousDay: onPreviousDay,
              onNextDay: onNextDay,
              child: CustomScrollView(
                controller: scrollController,
                slivers: [
                  // 日付の切り替えは、一覧をスクロールしても上部に残す
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _DateHeaderDelegate(
                      date: date,
                      canGoToPreviousDay: canGoToPreviousDay,
                      canGoToNextDay: canGoToNextDay,
                      onPreviousDay: onPreviousDay,
                      onNextDay: onNextDay,
                      onDateTap: onDateTap,
                    ),
                  ),
                  // 訪れた場所の取得が終わるまで表示する
                  if (isLoading)
                    const SliverToBoxAdapter(child: _LoadingIndicator()),
                  // 訪れた場所を取得できなかった滞在は、地名だけの表示になっている
                  // (ユーザーが場所名を入力した滞在は、取得できなくても困らない)
                  if (!isLoading &&
                      items.whereType<Stay>().any(
                        (e) => e.isPlaceSearchFailed && !e.isPlaceNameEdited,
                      ))
                    SliverToBoxAdapter(
                      child: _PlaceSearchFailedNotice(
                        onRetry: onRetryPlaceSearch,
                      ),
                    ),
                  if (items.isEmpty && !isLoading)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            "この日の行動履歴はありません",
                            style: TextStyle(color: AppColors.textSub),
                          ),
                        ),
                      ),
                    ),
                  // 左の余白12、右の余白16
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.space12,
                      0,
                      AppSizes.space16,
                      AppSizes.space24,
                    ),
                    sliver: SliverList.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) => _buildItem(
                        context,
                        items[index],
                        stayNumber: stayNumbers[index],
                        isFirst: index == 0,
                        isLast: index == items.length - 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildItem(
    BuildContext context,
    TimelineItem item, {
    required int? stayNumber,
    required bool isFirst,
    required bool isLast,
  }) {
    final time = TimelineFormatter.timeRange(item);

    return switch (item) {
      Stay() => _TimelineNode(
        isFirst: isFirst,
        isLast: isLast,
        node: Semantics(
          label: '$stayNumber番目の滞在',
          container: true,
          excludeSemantics: true,
          child: Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.navy,
            ),
            child: Text(
              '$stayNumber',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ),
        ),
        child: _buildStay(context, item, time),
      ),
      Move() => _TimelineNode(
        isFirst: isFirst,
        isLast: isLast,
        node: _lineNode(
          Icon(
            TimelineFormatter.transportIcon(item.transport),
            size: 16,
            color: AppColors.orange,
          ),
        ),
        child: _buildMove(context, item, time),
      ),
      // 記録していなかった時間帯は、滞在や移動より目立たない色で表示する
      RecordingOff() => _TimelineNode(
        isFirst: isFirst,
        isLast: isLast,
        node: _lineNode(
          const Icon(Icons.pause, size: 16, color: AppColors.chevron),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                TimelineFormatter.recordingOffTitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mutedText,
                ),
              ),
              Text(
                "$time（${TimelineFormatter.duration(item.duration)}）",
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSub,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    };
  }

  // 白い面に、うすい枠の丸(移動・記録のない時間の印)
  Widget _lineNode(Widget icon) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
      ),
      child: icon,
    );
  }

  // 編集のボタン(鉛筆。40x40)
  Widget _editButton({
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        fixedSize: const Size(40, 40),
        minimumSize: const Size(40, 40),
        padding: EdgeInsets.zero,
      ),
      icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSub),
    );
  }

  // 移動(カードにしない。選択中の移動は、地図上の経路と対応が分かるよう、ピンクにする)
  Widget _buildMove(BuildContext context, Move move, String time) {
    final selected = move.start == selectedMoveStart;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: selected ? AppColors.pink : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onMoveTap(move),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.space4,
              AppSizes.space4,
              AppSizes.space4,
              AppSizes.space4,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        TimelineFormatter.moveName(move),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      Text(
                        "約${TimelineFormatter.distance(move.distanceMeters)}"
                        " ・ $time（${TimelineFormatter.duration(move.duration)}）",
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSub,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                _editButton(
                  tooltip: "移動手段を編集",
                  onPressed: () => _editTransport(context, move),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 滞在(白いカード)
  Widget _buildStay(BuildContext context, Stay stay, String time) {
    final candidates = placeCandidates[stay.start] ?? const <PlaceCandidate>[];

    // ユーザーが確認していない滞在は、最も近い施設を訪れたものとして表示する。
    // 違っている場合は編集から直せるよう、推定であることと住所を添える
    final isEstimated = stay.isPlaceEstimated;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          boxShadow: AppColors.cardShadows,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onStayTap(stay),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.space16,
                AppSizes.space12,
                6,
                AppSizes.space12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          TimelineFormatter.stayTitle(
                            stay,
                            showNotFound: !isLoading,
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: AppSizes.space8,
                          runSpacing: 4,
                          children: [
                            Text(
                              time,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSub,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            // 滞在した時間の札
                            Container(
                              height: 20,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.space8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.pink,
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusPill,
                                ),
                              ),
                              child: Center(
                                widthFactor: 1,
                                child: Text(
                                  TimelineFormatter.duration(stay.duration),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.navyDark,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (isEstimated && stay.placeName != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              stay.placeName!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSub,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  _editButton(
                    tooltip: "場所を編集",
                    onPressed: () => _editPlace(context, stay, candidates),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 候補があれば候補から選び、なければ直接入力する
  Future<void> _editPlace(
    BuildContext context,
    Stay stay,
    List<PlaceCandidate> candidates,
  ) async {
    // 取得が終わるまでは、訪れた場所がないのか、まだ分からないのか区別できない
    if (isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("訪れた場所を取得しています。しばらくお待ちください")),
      );
      return;
    }

    // 通信に失敗した場合は、手入力せずに取得し直してもらう
    // (取得できていないだけの場所に、手入力した名前を残さないため)
    if (stay.isPlaceSearchFailed && !stay.isPlaceNameEdited) {
      await _showPlaceSearchFailed(context);
      return;
    }

    if (candidates.isEmpty) {
      await _editPlaceName(context, stay);
      return;
    }

    final choice = await showModalBottomSheet<_PlaceChoice>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text(
                  "訪れた場所を選択",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              for (final candidate in candidates)
                ListTile(
                  leading: const Icon(Icons.storefront),
                  title: Text(candidate.name),
                  subtitle: Text(
                    [
                      if (candidate.category != null) candidate.category!,
                      if (candidate.floor != null) candidate.floor!,
                      "約${candidate.distanceMeters.round()}m",
                    ].join("・"),
                  ),
                  onTap: () => Navigator.of(
                    context,
                  ).pop(_PlaceChoice.name(candidate.name)),
                ),
              // 自動で取得した住所のまま確定する
              if (!stay.isPlaceNameEdited && stay.placeName != null)
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: const Text("この中にない"),
                  subtitle: Text("「${stay.placeName}」のままにする"),
                  onTap: () => Navigator.of(
                    context,
                  ).pop(_PlaceChoice.name(stay.placeName!)),
                ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text("自分で入力"),
                onTap: () =>
                    Navigator.of(context).pop(const _PlaceChoice.manual()),
              ),
              if (stay.isPlaceNameEdited)
                ListTile(
                  leading: const Icon(Icons.clear),
                  title: const Text("自動に戻す"),
                  onTap: () =>
                      Navigator.of(context).pop(const _PlaceChoice.reset()),
                ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  "施設情報: © OpenStreetMap contributors",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        );
      },
    );

    if (choice == null) return;

    if (choice.isManual) {
      if (!context.mounted) return;
      await _editPlaceName(context, stay);
      return;
    }

    final placeName = choice.placeName;

    // 自動に戻す場合は、登録も取り消す
    if (placeName == null) {
      onPlaceNameChanged(stay, null);
      return;
    }

    if (!context.mounted) return;
    await _confirmRegister(context, stay, placeName);
  }

  Future<void> _showPlaceSearchFailed(BuildContext context) async {
    final retry = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("通信に失敗しました"),
        content: const Text(
          "訪れた場所を取得できませんでした。\n"
          "通信できる状態で、もう一度取得してください。",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("閉じる"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("再取得"),
          ),
        ],
      ),
    );

    if (retry == true) onRetryPlaceSearch();
  }

  Future<void> _editPlaceName(BuildContext context, Stay stay) async {
    final result = await showDialog<_PlaceNameResult>(
      context: context,
      builder: (context) => _PlaceNameDialog(stay: stay),
    );

    if (result == null) return;

    final placeName = result.placeName;

    // 自動に戻す場合は、登録も取り消す
    if (placeName == null) {
      onPlaceNameChanged(stay, null);
      return;
    }

    if (!context.mounted) return;
    await _confirmRegister(context, stay, placeName);
  }

  /// 場所名を自分で決めたときに、次回以降もその名前で表示する(登録する)かを尋ねて保存する
  /// (訪れた場所を取得できたかどうかにかかわらず尋ねる)
  Future<void> _confirmRegister(
    BuildContext context,
    Stay stay,
    String placeName,
  ) async {
    final register = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("この場所として登録しますか？"),
        content: Text(
          stay.isPlaceRegistered
              ? "登録すると、登録している名前を「$placeName」に変更します。\n"
                    "登録しない場合は、この滞在だけ「$placeName」にします。"
              : "次回以降も、この場所を訪れたときは「$placeName」と表示します。\n"
                    "登録しない場合は、この滞在だけ「$placeName」にして、"
                    "次回以降は訪れた場所を取得します。",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("いいえ"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("はい"),
          ),
        ],
      ),
    );

    onPlaceNameChanged(stay, placeName, registerPlace: register ?? false);
  }

  Future<void> _editTransport(BuildContext context, Move move) async {
    final result = await showModalBottomSheet<_TransportResult>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text(
                  "移動手段を選択",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              for (final mode in TransportMode.values)
                ListTile(
                  leading: Icon(TimelineFormatter.transportIcon(mode)),
                  title: Text(mode.label),
                  trailing: move.transport == mode
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () =>
                      Navigator.of(context).pop(_TransportResult.mode(mode)),
                ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text("文を自分で入力"),
                subtitle: const Text("例: 〇〇さんの車で移動"),
                onTap: () =>
                    Navigator.of(context).pop(const _TransportResult.text()),
              ),
              ListTile(
                leading: const Icon(Icons.clear),
                title: const Text("自動推定に戻す"),
                onTap: () =>
                    Navigator.of(context).pop(const _TransportResult.reset()),
              ),
            ],
          ),
        );
      },
    );

    if (result == null) return;

    if (result.isText) {
      if (!context.mounted) return;
      await _editTransportText(context, move);
      return;
    }

    // 移動手段を選び直した場合、以前の説明は合わなくなるため消す
    onTransportChanged(move, result.transport, null);
  }

  Future<void> _editTransportText(BuildContext context, Move move) async {
    final transport = move.transport;

    final text = await showDialog<String>(
      context: context,
      builder: (context) => _TextDialog(
        title: "移動の説明を編集",
        hintText: "例: 〇〇さんの車で移動",
        initialText:
            move.transportText ??
            (transport == null ? "" : "${transport.label}で移動"),
      ),
    );

    if (text == null) return;

    // 説明を空にした場合は、選んでいた移動手段だけを残す
    onTransportChanged(
      move,
      move.isTransportEdited || text.trim().isNotEmpty ? transport : null,
      text,
    );
  }
}

// キャンセル(null)と「元に戻す」(中身がnull)を区別するための入れ物
class _PlaceNameResult {
  const _PlaceNameResult(this.placeName);

  final String? placeName;
}

// 場所の選択結果(候補から選ぶ / 自分で入力 / 自動に戻す)
class _PlaceChoice {
  const _PlaceChoice.name(String this.placeName) : isManual = false;

  const _PlaceChoice.manual() : placeName = null, isManual = true;

  const _PlaceChoice.reset() : placeName = null, isManual = false;

  final String? placeName;
  final bool isManual;
}

// 移動手段の選択結果(手段を選ぶ / 文を自分で入力 / 自動推定に戻す)
class _TransportResult {
  const _TransportResult.mode(TransportMode this.transport) : isText = false;

  const _TransportResult.text() : transport = null, isText = true;

  const _TransportResult.reset() : transport = null, isText = false;

  final TransportMode? transport;
  final bool isText;
}

/// 1行の文を入力するダイアログ(保存した文を返す)
class _TextDialog extends StatefulWidget {
  const _TextDialog({
    required this.title,
    required this.hintText,
    required this.initialText,
  });

  final String title;
  final String hintText;
  final String initialText;

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  late final _controller = TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(hintText: widget.hintText),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("キャンセル"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text("保存"),
        ),
      ],
    );
  }
}

class _PlaceNameDialog extends StatefulWidget {
  const _PlaceNameDialog({required this.stay});

  final Stay stay;

  @override
  State<_PlaceNameDialog> createState() => _PlaceNameDialogState();
}

class _PlaceNameDialogState extends State<_PlaceNameDialog> {
  late final _controller = TextEditingController(
    text: widget.stay.placeName ?? "",
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("場所名を編集"),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: "例: 自宅、〇〇カフェ"),
      ),
      actions: [
        if (widget.stay.isPlaceNameEdited)
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(const _PlaceNameResult(null)),
            child: const Text("自動に戻す"),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("キャンセル"),
        ),
        ElevatedButton(
          onPressed: () =>
              Navigator.of(context).pop(_PlaceNameResult(_controller.text)),
          child: const Text("保存"),
        ),
      ],
    );
  }
}

/// 左右のスワイプで日付を切り替える
///
/// 指の動きに合わせて中身を横に動かし、指を離すと、今の日が画面の外へ流れて
/// 反対側から次の日が入ってくる。
class _DaySwipePager extends StatefulWidget {
  const _DaySwipePager({
    required this.canGoToPreviousDay,
    required this.canGoToNextDay,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.child,
  });

  final bool canGoToPreviousDay;
  final bool canGoToNextDay;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;
  final Widget child;

  @override
  State<_DaySwipePager> createState() => _DaySwipePagerState();
}

class _DaySwipePagerState extends State<_DaySwipePager>
    with SingleTickerProviderStateMixin {
  // 指を離したときに、この速さ以上で動いていれば切り替える
  static const _flingVelocity = 300.0;

  // 幅のこの割合以上動かしていれば、ゆっくり離しても切り替える
  static const _switchRatio = 0.3;

  // 切り替えられない方向へ引いたときの、動きにくさ
  static const _resistance = 0.25;

  // 中身の横方向の位置(0が通常の位置)
  late final _offset = AnimationController.unbounded(vsync: this);

  double _width = 0;
  bool _isSwitching = false;

  @override
  void dispose() {
    _offset.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_isSwitching) return;

    final next = _offset.value + details.delta.dx;
    final canGo = next > 0 ? widget.canGoToPreviousDay : widget.canGoToNextDay;

    _offset.value += canGo ? details.delta.dx : details.delta.dx * _resistance;
  }

  Future<void> _onDragEnd(DragEndDetails details) async {
    if (_isSwitching) return;

    final offset = _offset.value;
    final velocity = details.primaryVelocity ?? 0;

    // 右へ動かすと前の日、左へ動かすと次の日
    final toPrevious =
        widget.canGoToPreviousDay &&
        offset > 0 &&
        (offset > _width * _switchRatio || velocity > _flingVelocity);
    final toNext =
        widget.canGoToNextDay &&
        offset < 0 &&
        (offset < -_width * _switchRatio || velocity < -_flingVelocity);

    if (!toPrevious && !toNext) {
      // 切り替えない場合は、元の位置に戻す
      _offset.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
      return;
    }

    _isSwitching = true;
    final direction = toPrevious ? 1.0 : -1.0;

    // 今の日を、指を動かした方向の画面外へ流す
    await _offset.animateTo(
      direction * _width,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeIn,
    );
    if (!mounted) return;

    if (toPrevious) {
      widget.onPreviousDay();
    } else {
      widget.onNextDay();
    }

    // 切り替えた日を、反対側から入れる
    _offset.value = -direction * _width;
    await _offset.animateTo(
      0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );

    _isSwitching = false;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _width = constraints.maxWidth;

        return GestureDetector(
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          child: ClipRect(
            child: AnimatedBuilder(
              animation: _offset,
              child: widget.child,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_offset.value, 0),
                  child: child,
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// シートの上部に固定する、つまみと日付の切り替え(ホームの年月の切り替えと同じ見た目)
class _DateHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _DateHeaderDelegate({
    required this.date,
    required this.canGoToPreviousDay,
    required this.canGoToNextDay,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.onDateTap,
  });

  final DateTime date;
  final bool canGoToPreviousDay;
  final bool canGoToNextDay;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;
  final VoidCallback onDateTap;

  // つまみ(上の余白10 + 4 + 下12)と、日付の切り替え(40)と、下の余白(12)
  static const _height = 80.0;
  static const _weekdays = ["月", "火", "水", "木", "金", "土", "日"];

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final weekday = _weekdays[date.weekday - 1];

    return Material(
      color: AppColors.pageBackground,
      child: Column(
        children: [
          const _Handle(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.space16),
            child: SizedBox(
              height: 40,
              child: Row(
                children: [
                  RoundNavButton(
                    size: 40,
                    icon: Icons.chevron_left,
                    tooltip: "前の日",
                    onPressed: canGoToPreviousDay ? onPreviousDay : null,
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: onDateTap,
                      borderRadius: BorderRadius.circular(AppSizes.radius12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            "${date.year}年",
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSub,
                            ),
                          ),
                          const SizedBox(width: AppSizes.space4),
                          Text(
                            "${date.month}月${date.day}日",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(width: AppSizes.space4),
                          Text(
                            "（$weekday）",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSub,
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            size: 20,
                            color: AppColors.navy,
                          ),
                        ],
                      ),
                    ),
                  ),
                  RoundNavButton(
                    size: 40,
                    icon: Icons.chevron_right,
                    tooltip: "次の日",
                    onPressed: canGoToNextDay ? onNextDay : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_DateHeaderDelegate oldDelegate) {
    return oldDelegate.date != date ||
        oldDelegate.canGoToPreviousDay != canGoToPreviousDay ||
        oldDelegate.canGoToNextDay != canGoToNextDay;
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text("訪れた場所を取得しています…", style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _PlaceSearchFailedNotice extends StatelessWidget {
  const _PlaceSearchFailedNotice({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "一部の訪れた場所を取得できませんでした",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text("再取得")),
        ],
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(top: 10, bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.sheetHandle,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// タイムラインの1行(左に幅32の列。項目どうしを、点線でつなぐ)
///
/// 最初の項目の上と、最後の項目の下には、線を出さない
class _TimelineNode extends StatelessWidget {
  const _TimelineNode({
    required this.isFirst,
    required this.isLast,
    required this.node,
    required this.child,
  });

  final bool isFirst;
  final bool isLast;

  /// 左の列の、丸い印(直径28)
  final Widget node;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: CustomPaint(
              painter: _RailPainter(isFirst: isFirst, isLast: isLast),
              child: Center(child: node),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _RailPainter extends CustomPainter {
  const _RailPainter({required this.isFirst, required this.isLast});

  final bool isFirst;
  final bool isLast;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    // 丸い印は、行の真ん中にある。最初の行は印から下、最後の行は上から印まで
    final top = isFirst ? size.height / 2 : 0.0;
    final bottom = isLast ? size.height / 2 : size.height;

    final paint = Paint()
      ..color = AppColors.timelineDots
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (var y = top; y < bottom; y += 5) {
      canvas.drawLine(
        Offset(x, y),
        Offset(x, (y + 2).clamp(top, bottom)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RailPainter oldDelegate) =>
      oldDelegate.isFirst != isFirst || oldDelegate.isLast != isLast;
}
