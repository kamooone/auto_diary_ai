import '../../../memo/domain/entities/memo.dart';

/// 動作確認に使う、テスト用のひとことメモを作る
///
/// テスト用の日記と同じ期間に、1日0〜3件(平均1.2件ほど)。写真はつけない。
/// 文が[textPrefix]で始まるメモが、テスト用のメモ(削除のときの目印)
class TestMemoGenerator {
  const TestMemoGenerator._();

  static const textPrefix = "【テスト】";

  static bool isTestMemo(Memo memo) => memo.text.startsWith(textPrefix);

  /// [first]から[last]まで。同じ入力なら、いつも同じメモができる
  static List<Memo> generate({
    required DateTime first,
    required DateTime last,
  }) {
    final memos = <Memo>[];
    var index = 0;

    for (
      var day = DateTime(first.year, first.month, first.day);
      !day.isAfter(last);
      day = DateTime(day.year, day.month, day.day + 1), index++
    ) {
      final count = _counts[index % _counts.length];

      for (var i = 0; i < count; i++) {
        final time = _times[(index + i) % _times.length];
        final text = _texts[(index * 3 + i * 7) % _texts.length];

        memos.add(
          Memo(
            text: "$textPrefix$text",
            createdAt: DateTime(day.year, day.month, day.day, time.$1, time.$2),
          ),
        );
      }
    }

    return memos;
  }

  // 1日のメモの件数
  static const _counts = [1, 0, 2, 1, 1, 0, 3, 1, 0, 2, 1, 1, 2, 0];

  // メモの時刻(時, 分)
  static const _times = <(int, int)>[
    (7, 50),
    (12, 15),
    (19, 30),
    (22, 40),
    (10, 5),
    (15, 20),
  ];

  static const _texts = [
    "朝の電車がすいていて、座れた。",
    "昼はラーメン。スープまで飲んでしまった。",
    "夕焼けがきれいで、思わず立ち止まった。",
    "なんとなく疲れた。今日は早く寝る。",
    "コンビニの新作スイーツが当たりだった。",
    "同僚に、資料が分かりやすいと言われた。うれしい。",
    "雨が降ってきた。傘を持ってきて正解。",
    "久しぶりに友人から連絡が来た。",
    "ギターの練習、少しだけ弾けるようになった気がする。",
    "帰り道に、知らない小道を歩いてみた。",
    "カフェで読んだ本が面白くて、時間を忘れた。",
    "洗濯物がよく乾いた。気持ちいい。",
    "今日の夕飯は自分で作った。味はまあまあ。",
    "散歩中に、猫に会った。逃げられなかった。",
    "締め切りが近い。今夜がんばる。",
    "朝から頭が重い。水をたくさん飲もう。",
    "駅前に新しいパン屋ができていた。明日行ってみる。",
    "月がとても明るい夜だった。",
    "会議が思ったより早く終わって、少し得した気分。",
    "お風呂で、今日あったことをぼんやり思い返した。",
  ];
}
