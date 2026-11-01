import 'dart:io';
import 'package:auto_diary_ai/features/ai/domain/entities/ai_message_request.dart';
import 'package:auto_diary_ai/features/ai/domain/entities/ai_reply.dart';
import 'package:auto_diary_ai/features/ai/domain/repositories/ai_repository.dart';
import 'package:auto_diary_ai/features/diary/domain/entities/diary.dart';
import 'package:auto_diary_ai/features/diary_create/data/repositories/file_summary_style_repository.dart';
import 'package:auto_diary_ai/features/diary_create/domain/entities/summary_style.dart';
import 'package:auto_diary_ai/features/diary_create/domain/repositories/summary_style_repository.dart';
import 'package:auto_diary_ai/features/diary_create/domain/services/consult_reply_parser.dart';
import 'package:auto_diary_ai/features/diary_create/domain/services/summary_prompt.dart';
import 'package:auto_diary_ai/features/diary_create/domain/services/token_estimator.dart';
import 'package:auto_diary_ai/features/diary_create/presentation/viewmodel/summary_consult_view_model.dart';
import 'package:auto_diary_ai/features/ai/application/providers/ai_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Diary diary(int day, String title, String content) => Diary(
  date: DateTime(2026, 1, day),
  title: title,
  content: content,
  isAiGenerated: false,
  createdAt: DateTime(2026, 1, day),
);

final diaries = [diary(1, '初詣', '神社に行った'), diary(2, 'ラーメン', '同僚と食べた')];

String prompt(SummaryStyle style, {String custom = ''}) =>
    SummaryPrompt.build(
      style: style,
      diaries: diaries,
      note: '',
      customInstruction: custom,
    );

class ScriptedAi implements AiRepository {
  ScriptedAi(this.answers);

  final List<String> answers;
  final messages = <String>[];

  @override
  Future<AiReply> sendMessage(AiMessageRequest request) async {
    messages.add(request.message);
    return AiReply(answer: answers.removeAt(0));
  }
}

void main() {
  group('SummaryPrompt', () {
    test('どの書き方でも、日記の内容と、日記にないことは書かない決まりを渡す', () {
      for (final style in SummaryStyle.values) {
        final text = prompt(style, custom: '短く');

        expect(text, contains('2026年1月1日 初詣\n神社に行った'));
        expect(text, contains('付け足さないでください'));
        expect(text, contains('タイトル: (日記のタイトルを1行で)'));
      }
    });

    test('書き方ごとに、指示が違う', () {
      expect(prompt(SummaryStyle.reading), contains('形(読み物)'));
      expect(prompt(SummaryStyle.reading), contains('章立て'));
      expect(prompt(SummaryStyle.chronicle), contains('省略せずに'));
      expect(prompt(SummaryStyle.brief), contains('短い1本の文章'));
      expect(prompt(SummaryStyle.list), contains('「・○月○日 出来事」'));
    });

    test('自分で指定は、書いた指示を渡し、意味不明なときは読み物で書かせる', () {
      final text = prompt(SummaryStyle.custom, custom: 'ですます調で仕事だけ');

      expect(text, contains('ですます調で仕事だけ'));
      expect(text, contains('意味不明なとき'));
      expect(text, contains('形(読み物)'));
    });
  });

  group('TokenEstimator(書き方)', () {
    int estimate(SummaryStyle style) => TokenEstimator.estimate(
      note: '',
      timeline: const [],
      posts: const [],
      photoCount: 0,
      diaries: [diary(1, 't', 'あ' * 5000), diary(2, 't', 'あ' * 5000)],
      summaryStyle: style,
    );

    test('時系列の記録は、ほかより出力が多い見込みになる', () {
      expect(
        estimate(SummaryStyle.chronicle),
        greaterThan(estimate(SummaryStyle.reading)),
      );
      expect(
        estimate(SummaryStyle.reading),
        greaterThan(estimate(SummaryStyle.brief)),
      );
    });

    test('相談の最初の送信は、日記の量が増えると増える', () {
      expect(
        TokenEstimator.estimateConsult(diaries),
        lessThan(
          TokenEstimator.estimateConsult([
            diary(1, 't', 'あ' * 5000),
            diary(2, 't', 'あ' * 5000),
          ]),
        ),
      );
    });
  });

  group('ConsultReplyParser', () {
    final parser = ConsultReplyParser();

    test('回答・書き方の指示・材料メモに分ける', () {
      final reply = parser.parse(
        '【相談の回答】\n仕事が中心です。\n【書き方の指示】\n章立てで書く。\n【材料メモ】\n31件。仕事が多い。',
      );

      expect(reply.text, '仕事が中心です。');
      expect(reply.proposal, '章立てで書く。');
      expect(reply.brief, '31件。仕事が多い。');
    });

    test('書き方の指示がなければ、提案なし', () {
      final reply = parser.parse('【相談の回答】\nどんな長さがいいですか？');

      expect(reply.text, 'どんな長さがいいですか？');
      expect(reply.proposal, isNull);
    });

    test('見出しがなければ、全体を回答として扱う', () {
      final reply = parser.parse('おすすめは読み物です。');

      expect(reply.text, 'おすすめは読み物です。');
      expect(reply.proposal, isNull);
      expect(reply.brief, isNull);
    });
  });

  group('SummaryConsultViewModel', () {
    test('最初は日記の全文を送り、続けては材料メモと会話だけを送る', () async {
      final ai = ScriptedAi([
        '【相談の回答】\n仕事が中心です。\n【書き方の指示】\n章立てで書く。\n【材料メモ】\nMEMO-仕事中心',
        '【相談の回答】\n短くしますね。\n【書き方の指示】\n短く書く。',
      ]);
      final container = ProviderContainer(
        overrides: [aiRepositoryProvider.overrideWithValue(ai)],
      );
      addTearDown(container.dispose);
      container.listen(summaryConsultProvider, (_, __) {});

      final viewModel = container.read(summaryConsultProvider.notifier);
      await viewModel.start(diaries);

      var state = container.read(summaryConsultProvider);
      expect(state.messages.single.text, '仕事が中心です。');
      expect(state.messages.single.proposal, '章立てで書く。');
      expect(ai.messages[0], contains('神社に行った'));

      await viewModel.send('もっと短くして');

      state = container.read(summaryConsultProvider);
      expect(state.messages.map((e) => e.text), [
        '仕事が中心です。',
        'もっと短くして',
        '短くしますね。',
      ]);
      expect(state.messages.last.proposal, '短く書く。');

      // 2回目は、日記の全文を送らない
      expect(ai.messages[1], isNot(contains('神社に行った')));
      expect(ai.messages[1], contains('MEMO-仕事中心'));
      expect(ai.messages[1], contains('もっと短くして'));
      expect(ai.messages[1], contains('提案した書き方の指示: 章立てで書く。'));
    });
  });

  group('FileSummaryStyleRepository', () {
    late Directory dir;
    late FileSummaryStyleRepository repository;

    setUp(() {
      dir = Directory.systemTemp.createTempSync();
      repository = FileSummaryStyleRepository(
        () async => File('${dir.path}/style.json'),
      );
    });

    tearDown(() => dir.deleteSync(recursive: true));

    test('保存していなければ読み物', () async {
      final setting = await repository.load();

      expect(setting.style, SummaryStyle.reading);
      expect(setting.customInstruction, '');
    });

    test('前回の選択を覚えている', () async {
      await repository.save(
        const SummaryStyleSetting(
          style: SummaryStyle.custom,
          customInstruction: '短く',
        ),
      );

      final setting = await repository.load();
      expect(setting.style, SummaryStyle.custom);
      expect(setting.customInstruction, '短く');
    });
  });
}
