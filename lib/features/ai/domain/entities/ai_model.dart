/// 日記を書くAIの種類(ユーザーが選ぶ。プランとは別)
///
/// [modelName]は、サーバー(server/ai_chat/ai_chat_lambda.py)が実際に使うモデル名。
/// サーバー側のモデル(GEMINI_MODELSの先頭、OPENAI_MODEL)を変えたら、ここも直すこと
///
/// [dataNote]は、送った日記の扱い(提供元の規約による)。
/// Geminiは、無料枠(課金していないAPIキー)で使っている前提の内容。
/// GeminiのAPIキーを課金ありに変えたら、書き換えること。規約は変わるので、リリース前に確認する
enum AiModel {
  gemini(
    'Gemini',
    'gemini-flash-lite-latest',
    '速くて、使用量(トークン)の消費が少ないモデルです。'
        '混んでいるときは、別のGeminiのモデルに自動で切り替わります',
    '無料枠で使っているため、送った日記の内容は、Googleのサービスの改善に使われることがあります',
  ),
  gpt(
    'GPT',
    'gpt-4o-mini',
    'OpenAIの小型のモデルです。Geminiより、使用量(トークン)を多く消費する予定です',
    '送った日記の内容は、OpenAIのモデルの学習には使われません'
        '(不正利用の確認のため、最長30日間、保存されることがあります)',
  );

  const AiModel(this.label, this.modelName, this.feature, this.dataNote);

  final String label;

  /// 実際に使うモデルの名前
  final String modelName;

  /// モデルの特徴(短い説明)
  final String feature;

  /// 送った日記の扱い
  final String dataNote;

  /// 選択欄の下に出す、1行の説明
  String get description => '$modelNameで書きます';
}
