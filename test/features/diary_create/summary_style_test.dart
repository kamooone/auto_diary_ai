import 'dart:io';
import 'package:auto_diary_ai/features/ai/domain/entities/ai_message_request.dart';
import 'package:auto_diary_ai/features/ai/domain/entities/ai_reply.dart';
import 'package:auto_diary_ai/features/ai/domain/repositories/ai_repository.dart';
import 'package:auto_diary_ai/features/diary/domain/entities/diary.dart';
import 'package:auto_diary_ai/features/diary_create/data/repositories/file_summary_style_repository.dart';
import 'package:auto_diary_ai/features/diary_create/application/providers/diary_usecase_providers.dart';
import 'package:auto_diary_ai/features/diary_create/data/repositories/file_diary_style_repository.dart';
import 'package:auto_diary_ai/features/diary_create/domain/entities/diary_style.dart';
import 'package:auto_diary_ai/features/diary_create/domain/entities/summary_style.dart';
import 'package:auto_diary_ai/features/diary_create/domain/repositories/diary_style_repository.dart';
import 'package:auto_diary_ai/features/diary_create/domain/repositories/summary_style_repository.dart';
import 'package:auto_diary_ai/features/diary_create/presentation/providers/diary_create_provider.dart';
import 'package:auto_diary_ai/features/diary_create/domain/services/consult_reply_parser.dart';
import 'package:auto_diary_ai/features/diary_create/domain/services/summary_join.dart';
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

String prompt(SummaryStyle style, {String custom = ''}) => SummaryPrompt.build(
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

class MemoryStyleRepository implements SummaryStyleRepository {
  SummaryStyle saved = SummaryStyle.reading;

  @override
  Future<SummaryStyle> load() async => saved;

  @override
  Future<void> save(SummaryStyle style) async => saved = style;
}

class MemoryDiaryStyleRepository implements DiaryStyleRepository {
  DiaryStyle saved = DiaryStyle.diary;

  @override
  Future<DiaryStyle> load() async => saved;

  @override
  Future<void> save(DiaryStyle style) async => saved = style;
}

void main() {
  test('書き方は、決めた順番で並ぶ', () {
    expect(SummaryStyle.values.map((e) => e.label), [
      '日記を連結させる',
      '出来事の一覧',
      '読み物(簡単なブログ風)',
      '読み物(ブログ風)',
      '自分で指定',
    ]);
  });

  group('日記を連結させる(AIを使わない)', () {
    test('タイトルは、日記の期間から付ける', () {
      Diary on(int y, int m) => Diary(
        date: DateTime(y, m, 5),
        title: 't',
        content: 'c',
        isAiGenerated: false,
        createdAt: DateTime(y, m, 5),
      );

      expect(SummaryJoin.title([on(2026, 1), on(2026, 1)]), '2026年1月の日記');
      expect(SummaryJoin.title([on(2026, 3), on(2026, 1)]), '2026年1月〜3月の日記');
      expect(
        SummaryJoin.title([on(2026, 1), on(2025, 12)]),
        '2025年12月〜2026年1月の日記',
      );
    });

    test('AIを呼ばずに、日記を日付順につなぐ。保存するときは、AIの日記にしない', () async {
      final ai = ScriptedAi([]);
      final container = ProviderContainer(
        overrides: [
          aiRepositoryProvider.overrideWithValue(ai),
          summaryStyleRepositoryProvider.overrideWithValue(
            MemoryStyleRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.listen(diaryCreateProvider, (_, __) {});

      final viewModel = container.read(diaryCreateProvider.notifier);
      viewModel.setSummaryDiaries([
        diary(2, 'ラーメン', '同僚と食べた'),
        diary(1, '初詣', '神社に行った'),
      ]);
      viewModel.setSummaryStyle(SummaryStyle.chronicle);
      await viewModel.generateSummaryDiary();

      final state = container.read(diaryCreateProvider);
      expect(ai.messages, isEmpty);
      expect(state.generatedTitle, '2026年1月の日記');
      expect(
        state.generatedDiary,
        '2026年1月1日 初詣\n神社に行った\n\n2026年1月2日 ラーメン\n同僚と食べた',
      );
      expect(state.generatedByAi, isFalse);
      expect(state.isLoading, isFalse);
    });
  });

  group('ふつうの日記の、自分で指定', () {
    test('画面を離れて消すと、指示は空になり、日記に戻る', () {
      final container = ProviderContainer(
        overrides: [
          diaryStyleRepositoryProvider.overrideWithValue(
            MemoryDiaryStyleRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.listen(diaryCreateProvider, (_, __) {});

      final viewModel = container.read(diaryCreateProvider.notifier);
      viewModel.setDiaryStyle(DiaryStyle.custom);
      viewModel.setDiaryCustom('短く');
      viewModel.clearDiaryCustom();

      final state = container.read(diaryCreateProvider);
      expect(state.diaryStyle, DiaryStyle.diary);
      expect(state.diaryCustom, '');
    });

    test('前回の選択を覚えていて、自分で指定は日記に戻る', () async {
      final dir = Directory.systemTemp.createTempSync();
      addTearDown(() => dir.deleteSync(recursive: true));
      final repository = FileDiaryStyleRepository(
        () async => File('${dir.path}/style.json'),
      );

      expect(await repository.load(), DiaryStyle.diary);

      await repository.save(DiaryStyle.record);
      expect(await repository.load(), DiaryStyle.record);

      await repository.save(DiaryStyle.custom);
      expect(await repository.load(), DiaryStyle.diary);
    });
  });

  group('自分で指定の書き方の指示', () {
    test('画面を離れて消すと、指示は空になり、読み物に戻る', () {
      final repository = MemoryStyleRepository();
      final container = ProviderContainer(
        overrides: [
          summaryStyleRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      container.listen(diaryCreateProvider, (_, __) {});

      final viewModel = container.read(diaryCreateProvider.notifier);
      viewModel.applySummaryProposal('短く書く');

      var state = container.read(diaryCreateProvider);
      expect(state.summaryStyle, SummaryStyle.custom);
      expect(state.summaryCustom, '短く書く');

      viewModel.clearSummaryCustom();

      state = container.read(diaryCreateProvider);
      expect(state.summaryStyle, SummaryStyle.reading);
      expect(state.summaryCustom, '');
    });

    test('ほかの書き方を選んでいたときは、書き方はそのまま', () {
      final container = ProviderContainer(
        overrides: [
          summaryStyleRepositoryProvider.overrideWithValue(
            MemoryStyleRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.listen(diaryCreateProvider, (_, __) {});

      final viewModel = container.read(diaryCreateProvider.notifier);
      viewModel.setSummaryStyle(SummaryStyle.list);
      viewModel.clearSummaryCustom();

      expect(
        container.read(diaryCreateProvider).summaryStyle,
        SummaryStyle.list,
      );
    });
  });

  group('SummaryPrompt', () {
    test('どの書き方でも、日記の内容と、日記にないことは書かない決まりを渡す', () {
      for (final style in SummaryStyle.values) {
        final text = prompt(style, custom: '短く');

        expect(text, contains('■2026年1月1日 初詣\n神社に行った'));
        expect(text, contains('付け足さないでください'));
        expect(text, contains('タイトル: (日記のタイトルを1行で)'));
      }
    });

    test('書き方ごとに、指示が違う', () {
      expect(prompt(SummaryStyle.reading), contains('形(読み物)'));
      expect(prompt(SummaryStyle.reading), contains('章立て'));
      expect(prompt(SummaryStyle.reading), contains('2〜4文ごとの段落'));
      expect(prompt(SummaryStyle.reading), contains('羅列にしないでください'));
      expect(prompt(SummaryStyle.reading), contains('頻度の言葉は'));

      expect(prompt(SummaryStyle.brief), contains('読み物(ブログ風)を、もっと簡潔にした形'));
      expect(prompt(SummaryStyle.brief), contains('「○月○日」と日付を添えて'));
      expect(prompt(SummaryStyle.brief), contains('段落と段落の間は、1行空けてください'));
      expect(prompt(SummaryStyle.brief), contains('どの段落にも、「○月○日」と日付を添えた出来事を'));
      expect(prompt(SummaryStyle.brief), contains('日付が前に戻らないように'));
      expect(prompt(SummaryStyle.brief), contains('別の日の出来事を混ぜないでください'));
      expect(prompt(SummaryStyle.list), contains('「・○月○日 出来事」'));
      expect(prompt(SummaryStyle.list), contains('取り違えないでください'));
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

    test('日記を連結させるは、AIを使わないので、トークンは0', () {
      expect(estimate(SummaryStyle.chronicle), 0);
    });

    test('読み物(ブログ風)は読み物(簡単なブログ風)より出力が多い見込みになる', () {
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
      expect(await repository.load(), SummaryStyle.reading);
    });

    test('前回の選択を覚えている', () async {
      await repository.save(SummaryStyle.brief);

      expect(await repository.load(), SummaryStyle.brief);
    });

    test('自分で指定は、書いた指示を残さないので、読み物に戻る', () async {
      await repository.save(SummaryStyle.custom);

      expect(await repository.load(), SummaryStyle.reading);
    });
  });
}
