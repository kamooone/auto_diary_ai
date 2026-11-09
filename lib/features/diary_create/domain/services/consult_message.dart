/// 相談の途中の発言
class ConsultMessage {
  const ConsultMessage({
    required this.fromUser,
    required this.text,
    this.proposal,
    this.tokens,
  });

  final bool fromUser;
  final String text;

  /// この返答で使ったトークン数(AIの返答だけ。分からないときはnull)
  final int? tokens;

  /// AIが提案した書き方の指示(「自分で指定」にそのまま入れられる文章)
  final String? proposal;
}
