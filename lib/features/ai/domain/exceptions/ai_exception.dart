import '../../../plan/domain/entities/usage_info.dart';

/// 画像アップロード(ai-upload-url)の失敗
class AiUploadException implements Exception {
  final String message;

  AiUploadException(this.message);

  @override
  String toString() => 'AiUploadException: $message';
}

/// AI(Gemini・OpenAI)側が、混雑などで応答できなかった(サーバーが502を返した)。
/// このとき、トークンは使われない。少し時間をおくと、直ることが多い
class AiBusyException implements Exception {
  /// 原因を調べるための、サーバーが返した内容(長いものは切ってある)
  final String details;

  AiBusyException([this.details = '']);

  @override
  String toString() => 'AiBusyException: $details';
}

/// 日記の生成に時間がかかりすぎて、時間切れになった
/// (アプリが待つ時間・API Gatewayの60秒・サーバーがAIを待つ時間のどれか)。
/// 文字数の目安を大きくしていると、起きやすい
class AiTimeoutException implements Exception {
  @override
  String toString() => 'AiTimeoutException';
}

/// 日記生成(ai-chat)の失敗
class AiChatException implements Exception {
  final String message;

  AiChatException(this.message);

  @override
  String toString() => 'AiChatException: $message';
}

/// AIは答えたが、日記の本文が空だった(タイトルも本文も取り出せなかった)。
///
/// サーバーが見つけたときは、トークンは使われない([tokensUsed]がfalse)。
/// アプリが見つけたときは、回答はあったので、トークンが使われている場合がある
/// ([usage]は、そのあとの今月の使用量)
class AiEmptyDiaryException implements Exception {
  final UsageInfo? usage;
  final bool tokensUsed;

  AiEmptyDiaryException([this.usage, this.tokensUsed = true]);

  @override
  String toString() => 'AiEmptyDiaryException';
}

/// 選んだ内容に、AIに送れない内容(違法行為や暴力のやり方を求める発言など)が含まれている可能性がある。
///
/// サーバーが、AIに送る前に見つけて、断った(トークンは使われない)。
/// 日記の生成と、書き方の相談の、どちらでも起きる。
/// [sources]は、断った入力の名前(サーバーが返す)。案内で、どこを見直すかを伝えるために使う
class ContentBlockedException implements Exception {
  final List<String> sources;

  ContentBlockedException([this.sources = const []]);

  /// 入力の名前 → 案内に出す言い方
  static const _labels = {
    'note': '「追加で伝えたいこと」',
    'customInstruction': '「書き方の指定」',
    'memosText': '「ひとことメモ」',
    'postsText': '選んだ「Xの投稿」',
    'timelineText': '選んだ「行動履歴」',
    'diariesText': '選んだ「日記」の内容',
    'message': '送った「メッセージ」',
  };

  /// 利用者に見せる案内。どこが問題かが分かるときは、その場所を入れる
  String get message {
    final labels = [
      for (final source in sources)
        if (_labels.containsKey(source)) _labels[source]!,
    ];

    if (labels.isEmpty) {
      return 'AIに送れない内容(違法行為や暴力のやり方を求める内容など)が含まれている可能性があります。選んだ内容を見直してください。';
    }

    return '${labels.join('と')}に、AIに送れない内容(違法行為や暴力のやり方を求める内容など)が含まれている可能性があります。内容を見直してください。';
  }

  @override
  String toString() => 'ContentBlockedException: $sources';
}
