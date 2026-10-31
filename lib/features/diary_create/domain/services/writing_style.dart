/// AIが日記を書くときの、文体の希望(ユーザーが自由に直せる文章)
class WritingStyle {
  const WritingStyle._();

  /// 最初に入っている文章。気に入らなければ、ユーザーが書き換える
  static const defaultText =
      "一人称は「私」。「〜した」「〜だった」のように、です・ます調ではなく、素直な言い切りで書く。\n"
      "大げさな表現や決まり文句は使わず、見たこと・したことを具体的に書く。"
      "気持ちは一言ふれる程度にして、最後は短く締める。";

  /// プロンプトに差し込む部分(希望が空なら、何も差し込まない)
  static String section(String text) {
    final style = text.trim();
    if (style.isEmpty) return "";

    return "\n日記の書き方(ユーザーの希望。必ず従ってください)\n$style\n";
  }
}
