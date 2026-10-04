import 'package:flutter/material.dart';
import '../../../../location/domain/entities/timeline_item.dart';

/// 1日の行動(滞在した場所と移動)を時系列で表示するシート
class TimelineSheet extends StatelessWidget {
  const TimelineSheet({
    super.key,
    required this.items,
    required this.onStayTap,
  });

  final List<TimelineItem> items;
  final ValueChanged<Stay> onStayTap;

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
                Stay() => ListTile(
                    dense: true,
                    leading: const Icon(Icons.place),
                    title: Text(item.placeName ?? "場所名を取得できませんでした"),
                    subtitle: Text("$time（${_duration(item.duration)}）"),
                    onTap: () => onStayTap(item),
                  ),
                Move() => ListTile(
                    dense: true,
                    leading: const Icon(Icons.more_vert),
                    title: Text("移動 約${_distance(item.distanceMeters)}"),
                    subtitle: Text(time),
                  ),
              };
            },
          ),
        );
      },
    );
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
