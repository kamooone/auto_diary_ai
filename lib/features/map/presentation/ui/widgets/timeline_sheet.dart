import 'package:flutter/material.dart';
import '../../../../location/domain/entities/place_candidate.dart';
import '../../../../location/domain/entities/timeline_item.dart';
import '../../../../location/domain/entities/transport_mode.dart';

/// 1日の行動(滞在した場所と移動)を時系列で表示するシート
class TimelineSheet extends StatelessWidget {
  const TimelineSheet({
    super.key,
    required this.items,
    required this.placeCandidates,
    required this.onStayTap,
    required this.onPlaceNameChanged,
    required this.onTransportChanged,
  });

  final List<TimelineItem> items;

  /// 滞在の開始時刻ごとの、周辺の施設の候補
  final Map<DateTime, List<PlaceCandidate>> placeCandidates;

  final ValueChanged<Stay> onStayTap;

  /// 場所名がnullの場合は、自動で取得した場所名に戻す
  final void Function(Stay stay, String? placeName) onPlaceNameChanged;

  /// 移動手段と、移動の説明(自由に書いた文)
  /// どちらもnullの場合は、自動推定に戻す
  final void Function(Move move, TransportMode? transport, String? text)
      onTransportChanged;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.25,
      minChildSize: 0.1,
      maxChildSize: 0.7,
      builder: (context, scrollController) {
        return Material(
          elevation: 8,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: ListView.builder(
            controller: scrollController,
            padding: EdgeInsets.zero,
            itemCount: items.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return const _Handle();
              }

              final item = items[index - 1];
              final time = "${_time(item.start)}〜${_time(item.end)}";

              return switch (item) {
                Stay() => _buildStay(context, item, time),
                Move() => ListTile(
                    dense: true,
                    leading: Icon(_transportIcon(item.transport)),
                    title: Text(_moveTitle(item)),
                    subtitle: Text(time),
                    trailing: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(Icons.edit, size: 18),
                    ),
                    onTap: () => _editTransport(context, item),
                  ),
              };
            },
          ),
        );
      },
    );
  }

  Widget _buildStay(BuildContext context, Stay stay, String time) {
    final candidates = placeCandidates[stay.start] ?? const <PlaceCandidate>[];

    final name = stay.displayName ?? "場所名を取得できませんでした";
    final timeText = "$time（${_duration(stay.duration)}）";

    // ユーザーが確認していない滞在は、最も近い施設を訪れたものとして表示する。
    // 違っている場合は編集から直せるよう、推定であることと住所を添える
    final isEstimated = stay.isPlaceEstimated;

    return ListTile(
      dense: true,
      leading: const Icon(Icons.place),
      title: Text(isEstimated ? "$name（推定）" : name),
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

  String _moveTitle(Move move) {
    final distance = "約${_distance(move.distanceMeters)}";

    // ユーザーが書いた説明があれば、それをそのまま表示する
    final text = move.transportText;
    if (text != null) return "$text $distance";

    final transport = move.transport;

    if (transport == null) return "移動 $distance";

    return move.isTransportEdited
        ? "${transport.label}で移動 $distance"
        : "${transport.label}で移動（推定） $distance";
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
                  leading: Icon(_transportIcon(mode)),
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

  IconData _transportIcon(TransportMode? transport) {
    return switch (transport) {
      TransportMode.walk => Icons.directions_walk,
      TransportMode.bicycle => Icons.directions_bike,
      TransportMode.vehicle => Icons.commute,
      TransportMode.car => Icons.directions_car,
      TransportMode.bus => Icons.directions_bus,
      TransportMode.train => Icons.train,
      TransportMode.other => Icons.more_horiz,
      null => Icons.more_vert,
    };
  }

  String _time(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  String _duration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return hours > 0 ? "$hours時間$minutes分" : "$minutes分";
  }

  String _distance(double meters) {
    return meters >= 1000
        ? "${(meters / 1000).toStringAsFixed(1)}km"
        : "${meters.round()}m";
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
