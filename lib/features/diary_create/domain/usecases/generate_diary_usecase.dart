import '../../../ai/domain/usecases/send_message_usecase.dart';

class GenerateDiaryUseCase {
  final SendMessageUseCase _sendMessageUseCase;

  GenerateDiaryUseCase(this._sendMessageUseCase);

  Future<String> execute({
    required String title,
    required String content,
    required DateTime date,
  }) async {
    final input = """
タイトル: $title
本文: $content
日付: $date
""";

    return await _sendMessageUseCase.execute(
      "あなたは優秀な日記作成AIです。\n"
          "以下の情報から自然な日記を書いてください。\n\n"
          "$input",
    );
  }
}