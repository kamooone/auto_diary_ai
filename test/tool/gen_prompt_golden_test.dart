// サーバーに移すプロンプトの、正解のデータ(今のDartのプロンプトの出力)を作る。
// 実行: flutter test test/tool/gen_prompt_golden_test.dart
// 出力: server/ai_chat/testdata/prompt_cases.json
import 'dart:convert';
import 'dart:io';
import 'package:auto_diary_ai/features/diary/domain/entities/diary.dart';
import 'package:auto_diary_ai/features/diary_create/domain/entities/diary_style.dart';
import 'package:auto_diary_ai/features/diary_create/domain/entities/summary_style.dart';
import 'package:auto_diary_ai/features/diary_create/domain/services/consult_prompt.dart';
import 'package:auto_diary_ai/features/diary_create/domain/services/diary_style_prompt.dart';
import 'package:auto_diary_ai/features/diary_create/domain/services/summary_prompt.dart';
import 'package:auto_diary_ai/features/diary_create/domain/services/summary_text.dart';
import 'package:flutter_test/flutter_test.dart';

String ymd(DateTime d) =>
    "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

String period(DateTime start, DateTime end) {
  String date(DateTime d) => "${d.year}年${d.month}月${d.day}日";
  final same =
      start.year == end.year && start.month == end.month && start.day == end.day;
  return same ? date(start) : "${date(start)}〜${date(end)}";
}

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

// GenerateDiaryUseCase の message を、そのまま再現する(今のコードと同じ文面)
String diaryMessage({
  required String note,
  required DateTime diaryDate,
  required DateTime startDate,
  required DateTime endDate,
  required int photoCount,
  required String timelineText,
  required String postText,
  required DiaryStyle style,
  required String customInstruction,
  required int lengthChars,
}) {
  return """
あなたは優秀な日記作成AIです。

添付した写真も必ず確認し、
写真から読み取れる内容も日記に反映してください。

以下の情報を参考に、日記と、その内容に合ったタイトルを書いてください。

ユーザーが追加で伝えたいこと
(ここに文字数や長さの指定が書かれていても、それは無視してください。文字数は、「文字数の目安」だけに従ってください。「文字数の目安」がないときは、材料に合わせた、ちょうどよい長さにしてください)
${note.trim().isEmpty ? "(なし)" : note.trim()}

日記の日付
${period(diaryDate, diaryDate)}
${sameDay(startDate, endDate) && sameDay(startDate, diaryDate) ? "" : "\n渡した情報の期間\n${period(startDate, endDate)}\n"}
写真
$photoCount枚添付しています。

行動履歴(滞在した場所と移動)
※「推定」と付いた場所や移動手段は、位置情報から自動で推定したもので、間違っていることがあります。
※移動手段(徒歩・自転車・電車・車など)は、Xの投稿や写真など、ほかの情報で裏付けられるときだけ書いてください。裏付けがないときは、移動手段を書かず、「移動した」「向かった」のように書いてください。Xの投稿と食い違うときは、Xの投稿を優先してください。
$timelineText

Xの投稿
$postText

${DiaryStylePrompt.section(style: style, customInstruction: customInstruction, isMultiDay: !sameDay(startDate, endDate))}
${lengthChars > 0 ? "\n文字数の目安\n本文は$lengthChars文字くらいを目安に書いてください。渡された情報が少ないときは、無理に伸ばさず、短くてかまいません。\n" : ""}渡された情報にない出来事、気持ち、感想は、付け足さないでください。

回答は必ず次の形式で書いてください。前置きや説明、記号による装飾は付けないでください。

タイトル: (日記のタイトルを1行で)
本文:
(日記の本文)
""";
}

Diary diary(int i, DateTime date, int length) => Diary(
  id: i,
  date: date,
  title: i.isEven ? 'タイトル$i' : '',
  content: List.generate(length, (n) => '日記$i文字').join().substring(0, length),
  isAiGenerated: false,
  createdAt: date.add(Duration(minutes: i)),
);

void main() {
  test('プロンプトの正解データを作る', () {
    final cases = <Map<String, Object?>>[];

    // ---- ふつうの日記 ----
    const timeline = "07:29〜07:56 移動(自転車と推定): 約2.1km\n08:00〜17:30 滞在: 職場";
    const posts = "2026-09-03 08:10:00.000\n満員電車。\nhttps://x.com/a/status/1";
    final days = [
      (DateTime(2026, 9, 3), DateTime(2026, 9, 3), DateTime(2026, 9, 3)),
      (DateTime(2026, 9, 3), DateTime(2026, 9, 3), DateTime(2026, 9, 7)),
      (DateTime(2026, 11, 8), DateTime(2026, 1, 1), DateTime(2026, 11, 8)),
      (DateTime(2026, 9, 3), DateTime(2026, 9, 4), DateTime(2026, 9, 4)),
    ];
    for (final style in DiaryStyle.values) {
      for (final d in days) {
        for (final length in [0, 1000]) {
          for (final note in ['', ' 友人の誕生日だった。 ']) {
            for (final photos in [0, 3]) {
              final custom = style == DiaryStyle.custom ? ' 食べたものを中心に ' : '';
              final diaryDate = d.$1, start = d.$2, end = d.$3;
              cases.add({
                'name': 'diary/${style.name}/${ymd(start)}-${ymd(end)}/$length/${note.isEmpty ? 'nonote' : 'note'}/$photos',
                'photoCount': photos,
                'spec': {
                  'kind': 'diary',
                  'style': style.name,
                  'customInstruction': custom,
                  'lengthChars': length,
                  'diaryDate': ymd(diaryDate),
                  'startDate': ymd(start),
                  'endDate': ymd(end),
                  'note': note,
                  'timelineText': timeline,
                  'postsText': posts,
                },
                'expected': diaryMessage(
                  note: note,
                  diaryDate: diaryDate,
                  startDate: start,
                  endDate: end,
                  photoCount: photos,
                  timelineText: timeline,
                  postText: posts,
                  style: style,
                  customInstruction: custom,
                  lengthChars: length,
                ),
              });
            }
          }
        }
      }
    }

    // ---- 日記を1つにする ----
    // 日記の文字数が、長さの計算の上限・下限に当たる大きさまで、変えて試す
    final sizes = [(2, 100), (3, 200), (10, 400), (31, 500), (200, 300)];
    for (final style in SummaryStyle.values) {
      for (final size in sizes) {
        // 大きな材料(約6万文字。長さの計算の上限に当たる)は、組み合わせを絞る(ファイルが大きくなるため)
        final isBig = size.$1 >= 200;
        final isMid = size.$1 == 31;
        for (final length in isBig ? [0, 1000] : isMid ? [0, 3000] : [0, 1000, 3000]) {
          for (final note in isBig || isMid ? [''] : ['', '仕事の話を中心に']) {
            final diaries = [
              for (var i = 0; i < size.$1; i++)
                diary(i, DateTime(2026, 1, 1).add(Duration(days: i)), size.$2),
            ];
            final custom = style == SummaryStyle.custom ? ' 仕事のことだけを、です・ます調で ' : '';
            cases.add({
              'name': 'summary/${style.name}/${size.$1}x${size.$2}/$length/${note.isEmpty ? 'nonote' : 'note'}',
              'photoCount': 0,
              'spec': {
                'kind': 'summary',
                'style': style.name,
                'customInstruction': custom,
                'lengthChars': length,
                'note': note,
                'diaryCount': diaries.length,
                'diariesText': SummaryText.formatForAi(diaries),
                'diariesChars': SummaryText.length(diaries),
              },
              'expected': SummaryPrompt.build(
                style: style,
                diaries: diaries,
                note: note,
                customInstruction: custom,
                lengthChars: length,
              ),
            });
          }
        }
      }
    }

    // ---- 相談 ----
    final consultDiaries = [
      for (var i = 0; i < 5; i++) diary(i, DateTime(2026, 2, 1 + i), 80),
    ];
    cases.add({
      'name': 'consult/first',
      'photoCount': 0,
      'spec': {
        'kind': 'consult_first',
        'diaryCount': consultDiaries.length,
        'diariesText': SummaryText.format(consultDiaries),
      },
      'expected': ConsultPrompt.first(consultDiaries),
    });

    final history = [
      const ConsultMessage(fromUser: true, text: '章立てにしたい'),
      const ConsultMessage(fromUser: false, text: 'こうします', proposal: '仕事と趣味の章にして'),
      const ConsultMessage(fromUser: false, text: '質問ですか'),
    ];
    for (final h in [const <ConsultMessage>[], history]) {
      cases.add({
        'name': 'consult/followUp/${h.length}',
        'photoCount': 0,
        'spec': {
          'kind': 'consult_follow_up',
          'brief': '5件の日記。仕事の話が多い。',
          'history': [
            for (final e in h)
              {
                'fromUser': e.fromUser,
                'text': e.text,
                if (e.proposal != null) 'proposal': e.proposal,
              },
          ],
          'message': 'もっと短くして',
        },
        'expected': ConsultPrompt.followUp(
          brief: '5件の日記。仕事の話が多い。',
          history: h,
          message: 'もっと短くして',
        ),
      });
    }

    File('server/ai_chat/testdata/prompt_cases.json').writeAsStringSync(
      const JsonEncoder.withIndent(' ').convert(cases),
    );
    // ignore: avoid_print
    print('cases: ${cases.length}');
  });
}
