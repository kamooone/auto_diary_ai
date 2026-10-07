import 'package:flutter/material.dart';
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
  final void Function(Stay stay, String? placeName) onPlaceNameChanged;

  /// 移動手段と、移動の説明(自由に書いた文)
  /// どちらもnullの場合は、自動推定に戻す
  final void Function(Move move, TransportMode? transport, String? text)
      onTransportChanged;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: controller,
      initialChildSize: 0.25,
      minChildSize: minSize,
      maxChildSize: 0.7,
      builder: (context, scrollController) {
        return Material(
          elevation: 8,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          clipBehavior: Clip.antiAlias,
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
              if (items.isEmpty && !isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text("この日の行動履歴はありません")),
                  ),
                ),
              SliverList.builder(
                itemCount: items.length,
                itemBuilder: (context, index) =>
                    _buildItem(context, items[index]),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItem(BuildContext context, TimelineItem item) {
    final time = TimelineFormatter.timeRange(item);

    return switch (item) {
      Stay() => _buildStay(context, item, time),
      Move() => ListTile(
          dense: true,
          leading: Icon(TimelineFormatter.transportIcon(item.transport)),
          title: Text(TimelineFormatter.moveTitle(item)),
          subtitle: Text(time),
          // 選択中の移動は、地図上の経路と対応が分かるよう色を付ける
          selected: item.start == selectedMoveStart,
          selectedTileColor: Theme.of(context)
              .colorScheme
              .primary
              .withValues(alpha: 0.12),
          trailing: IconButton(
            icon: const Icon(Icons.edit, size: 18),
            tooltip: "移動手段を編集",
            onPressed: () => _editTransport(context, item),
          ),
          onTap: () => onMoveTap(item),
        ),
    };
  }

  Widget _buildStay(BuildContext context, Stay stay, String time) {
    final candidates = placeCandidates[stay.start] ?? const <PlaceCandidate>[];

    final timeText =
        "$time（${TimelineFormatter.duration(stay.duration)}）";

    // ユーザーが確認していない滞在は、最も近い施設を訪れたものとして表示する。
    // 違っている場合は編集から直せるよう、推定であることと住所を添える
    final isEstimated = stay.isPlaceEstimated;

    return ListTile(
      dense: true,
      leading: const Icon(Icons.place),
      title: Text(TimelineFormatter.stayTitle(stay)),
      subtitle: Text(
        isEstimated && stay.placeName != null
            ? "$timeText\n${stay.placeName}"
            : timeText,
      ),
      isThreeLine: isEstimated && stay.placeName != null,
      trailing: IconButton(
        icon: const Icon(Icons.edit, size: 18),
        tooltip: "場所を編集",
        onPressed: () => _editPlace(context, stay, candidates),
      ),
      onTap: () => onStayTap(stay),
    );
  }

  /// 候補があれば候補から選び、なければ直接入力する
  Future<void> _editPlace(
    BuildContext context,
    Stay stay,
    List<PlaceCandidate> candidates,
  ) async {
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
                      "約${candidate.distanceMeters.round()}m",
                    ].join("・"),
                  ),
                  onTap: () => Navigator.of(context)
                      .pop(_PlaceChoice.name(candidate.name)),
                ),
              // 自動で取得した住所のまま確定する
              if (!stay.isPlaceNameEdited && stay.placeName != null)
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: const Text("この中にない"),
                  subtitle: Text("「${stay.placeName}」のままにする"),
                  onTap: () => Navigator.of(context)
                      .pop(_PlaceChoice.name(stay.placeName!)),
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

    onPlaceNameChanged(stay, choice.placeName);
  }

  Future<void> _editPlaceName(BuildContext context, Stay stay) async {
    final result = await showDialog<_PlaceNameResult>(
      context: context,
      builder: (context) => _PlaceNameDialog(stay: stay),
    );

    if (result != null) {
      onPlaceNameChanged(stay, result.placeName);
    }
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
                  trailing:
                      move.transport == mode ? const Icon(Icons.check) : null,
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
        initialText: move.transportText ??
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

  const _PlaceChoice.manual()
      : placeName = null,
        isManual = true;

  const _PlaceChoice.reset()
      : placeName = null,
        isManual = false;

  final String? placeName;
  final bool isManual;
}

// 移動手段の選択結果(手段を選ぶ / 文を自分で入力 / 自動推定に戻す)
class _TransportResult {
  const _TransportResult.mode(TransportMode this.transport) : isText = false;

  const _TransportResult.text()
      : transport = null,
        isText = true;

  const _TransportResult.reset()
      : transport = null,
        isText = false;

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
        decoration: const InputDecoration(
          hintText: "例: 自宅、〇〇カフェ",
        ),
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

/// シートの上部に固定する、つまみと日付の切り替え
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

  static const _height = 68.0;
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
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          const _Handle(),
          SizedBox(
            height: 48,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: "前の日",
                  onPressed: canGoToPreviousDay ? onPreviousDay : null,
                ),
                Expanded(
                  child: InkWell(
                    onTap: onDateTap,
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${date.year}年${date.month}月${date.day}日($weekday)",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: "次の日",
                  onPressed: canGoToNextDay ? onNextDay : null,
                ),
              ],
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
          Text(
            "訪れた場所を取得しています…",
            style: Theme.of(context).textTheme.bodySmall,
          ),
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
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[400],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
