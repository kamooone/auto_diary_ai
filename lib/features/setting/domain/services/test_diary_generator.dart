import '../../../diary/domain/entities/diary.dart';

/// まとめ日記の動作確認に使う、テスト用の日記を作る
///
/// 日記を1件ずつ書かなくても、まとめ日記を試せるようにするためのもの。
/// タイトルが[titlePrefix]で始まる日記が、テスト用の日記
class TestDiaryGenerator {
  const TestDiaryGenerator._();

  static const titlePrefix = "【テスト】";

  static bool isTestDiary(Diary diary) => diary.title.startsWith(titlePrefix);

  /// [first]から[last]まで、1日1件(各500文字前後)
  static List<Diary> generate({required DateTime first, required DateTime last}) {
    final diaries = <Diary>[];
    var index = 0;

    for (
      var day = DateTime(first.year, first.month, first.day);
      !day.isAfter(last);
      day = DateTime(day.year, day.month, day.day + 1), index++
    ) {
      diaries.add(
        Diary(
          date: day,
          title: "$titlePrefix${day.month}月${day.day}日の日記",
          content: _content(day, index),
          isAiGenerated: false,
          createdAt: DateTime(day.year, day.month, day.day, 21),
        ),
      );
    }

    return diaries;
  }

  // 日によって、文の組み合わせが変わる
  static String _content(DateTime day, int index) {
    final sentences = [
      for (var i = 0; i < 11; i++) _sentences[(index * 3 + i) % _sentences.length],
    ];

    return "${day.month}月${day.day}日。${sentences.join()}";
  }

  static const _sentences = [
    "朝は少し早めに起きて、温かいお茶を飲みながらゆっくり新聞に目を通した。",
    "昼には近所の食堂で定食を食べて、午後の仕事に向けて気持ちを整えた。",
    "仕事では新しい企画の打ち合わせがあり、思ったより多くの意見が出て刺激を受けた。",
    "帰り道に夕焼けがとてもきれいで、足を止めてしばらく空を眺めていた。",
    "夜は久しぶりに友人から連絡があり、近いうちに会おうという話になった。",
    "最近読み始めた小説が面白く、寝る前に気づけば一時間も読み続けていた。",
    "散歩の途中で見つけた小さな喫茶店が気になって、今度ゆっくり寄ってみたい。",
    "夕食は自分で作ったカレーで、少し煮込みすぎたけれど味はなかなか良かった。",
    "掃除をして部屋がすっきりしたので、気分まで軽くなったように感じた。",
    "天気が変わりやすい一日で、傘を持って出かけて正解だったと思った。",
    "家族と電話で話して、近況を伝え合ううちに自然と笑顔になっていた。",
    "少し疲れが残っていたので、今日は早めにお風呂に入って体を休めることにした。",
    "新しく始めた運動を続けられていることが、ささやかな自信につながっている。",
    "買い物で季節の果物を見つけて、つい手に取ってしまい、帰ってから大切に食べた。",
  ];
}
