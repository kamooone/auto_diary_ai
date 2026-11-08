/// 相談に対するAIの返答
class ConsultReply {
  const ConsultReply({required this.text, this.proposal, this.brief});

  /// ユーザーに見せる文章
  final String text;

  /// 提案された書き方の指示(なければnull)
  final String? proposal;

  /// 材料の分析メモ(最初の返答にだけ付く。なければnull)
  final String? brief;
}

/// AIの返答を、ユーザーに見せる文章・書き方の指示・材料メモに分ける
///
/// 指示どおりの見出しがなかった場合は、返答全体をユーザーに見せる文章として扱う。
class ConsultReplyParser {
  static final _marker = RegExp(r'【(相談の回答|書き方の指示|材料メモ)】');

  ConsultReply parse(String answer) {
    final matches = _marker.allMatches(answer).toList();
    if (matches.isEmpty) return ConsultReply(text: answer.trim());

    final sections = <String, String>{};
    for (var i = 0; i < matches.length; i++) {
      final end = i + 1 < matches.length ? matches[i + 1].start : answer.length;
      sections.putIfAbsent(
        matches[i].group(1)!,
        () => answer.substring(matches[i].end, end).trim(),
      );
    }

    final proposal = sections['書き方の指示'];
    final brief = sections['材料メモ'];
    final text = sections['相談の回答'] ?? answer.substring(0, matches.first.start).trim();

    return ConsultReply(
      text: text.isEmpty ? answer.trim() : text,
      proposal: proposal == null || proposal.isEmpty ? null : proposal,
      brief: brief == null || brief.isEmpty ? null : brief,
    );
  }
}
