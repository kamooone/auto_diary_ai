/// 日記を書くAIの種類(ユーザーが選ぶ。プランとは別)
enum AiModel {
  gemini('Gemini', 'Googleのモデル(無料枠)で書きます'),
  gpt('GPT', 'OpenAIのモデルで書きます');

  const AiModel(this.label, this.description);

  final String label;
  final String description;
}
