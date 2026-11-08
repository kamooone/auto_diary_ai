/// 日記を書くAIの種類(ユーザーが選ぶ。プランとは別)
///
/// [modelName]は、サーバー(server/ai_chat/ai_chat_lambda.py)が実際に使うモデル名。
/// サーバー側のモデル(GEMINI_MODELSの先頭、OPENAI_MODEL)を変えたら、ここも直すこと
///
/// [dataNote]は、送った日記の扱い(提供元の規約による)。
/// Geminiは、無料枠(課金していないAPIキー)で使っている前提の内容。
/// GeminiのAPIキーを課金ありに変えたら、書き換えること。規約は変わるので、リリース前に確認する
///
/// [writing]は、書き上がる文章の傾向。実機で、同じ日記353件(1月〜10月)をブログ風にして
/// 比べた結果から書いた(2026-11-07)。モデルやプロンプトを変えたら、見直すこと
enum AiModel {
  gemini(
    'Gemini',
    'gemini-flash-lite-latest',
    '速くて、使用量(トークン)の消費が少ないモデルです。'
        '混んでいるときは、少し待って、自動でやり直します',
    '日記に書かれた出来事に忠実で、日記にないことを付け足しにくい傾向です。'
        '期間が長いと、後半は、日記の文に近い書き方になることがあります',
    '無料枠で使っているため、送った日記の内容は、Googleのサービスの改善に使われることがあります',
  ),
  gpt(
    'GPT',
    'gpt-5-mini',
    'OpenAIの小型のモデルです。日付や出来事を取り違えにくく、Geminiより、使用量(トークン)を多く消費する予定です',
    '文章がなめらかで、前後のつながりのある読み物になりやすい傾向です。'
        '日記にない一言が入ることがあるので、保存の前に確認してください',
    '送った日記の内容は、OpenAIのモデルの学習には使われません'
        '(不正利用の確認のため、最長30日間、保存されることがあります)',
  );

  const AiModel(
    this.label,
    this.modelName,
    this.feature,
    this.writing,
    this.dataNote,
  );

  final String label;

  /// 実際に使うモデルの名前
  final String modelName;

  /// モデルの特徴(短い説明)
  final String feature;

  /// 書き上がる文章の傾向
  final String writing;

  /// 送った日記の扱い
  final String dataNote;

  /// 選択欄の下に出す、1行の説明
  String get description => '$modelNameで書きます';
}
