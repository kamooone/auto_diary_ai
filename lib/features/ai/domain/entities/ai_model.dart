/// 日記を書くAIの種類(ユーザーが選ぶ。プランとは別)
///
/// [modelName]は、サーバー(server/ai_chat/ai_chat_lambda.py)が実際に使うモデル名。
/// サーバー側のモデル(GEMINI_MODELSの先頭、OPENAI_MODEL)を変えたら、ここも直すこと
enum AiModel {
  gemini(
    'Gemini',
    'gemini-flash-lite-latest',
    '速くて、使用量(トークン)の消費が少ないモデルです。'
        '混んでいるときは、別のGeminiのモデルに自動で切り替わります',
  ),
  gpt(
    'GPT',
    'gpt-4o-mini',
    'OpenAIの小型のモデルです。Geminiより、使用量(トークン)を多く消費する予定です',
  );

  const AiModel(this.label, this.modelName, this.feature);

  final String label;

  /// 実際に使うモデルの名前
  final String modelName;

  /// モデルの特徴(短い説明)
  final String feature;

  /// 選択欄の下に出す、1行の説明
  String get description => '$modelNameで書きます';
}
