import '../entities/generated_diary.dart';

/// AIの回答を、タイトルと本文に分ける
///
/// AIには次の形式で書くよう指示している。
///
///     タイトル: (タイトル)
///     本文:
///     (本文)
///
/// 指示どおりの形式でなかった場合は、回答全体を本文として扱う。
class GeneratedDiaryParser {
  static final _titlePattern = RegExp(r'^[#*\s]*タイトル[*\s]*[:：]\s*(.*)$');
  static final _contentPattern = RegExp(r'^[#*\s]*本文[*\s]*[:：]\s*(.*)$');

  GeneratedDiary parse(String answer) {
    final lines = answer.trim().split('\n');

    // 先頭の空行を除いた最初の行がタイトルでなければ、形式に従っていない
    final titleIndex = lines.indexWhere((line) => line.trim().isNotEmpty);
    final titleMatch =
        titleIndex < 0 ? null : _titlePattern.firstMatch(lines[titleIndex].trim());

    if (titleMatch == null) {
      return GeneratedDiary(title: '', content: answer.trim());
    }

    final title = _stripDecoration(titleMatch.group(1) ?? '');
    final rest = lines.sublist(titleIndex + 1);

    // 「本文:」の行があれば、その後ろを本文とする(同じ行に続きがあれば含める)
    final contentIndex = rest.indexWhere((line) => line.trim().isNotEmpty);
    final contentMatch = contentIndex < 0
        ? null
        : _contentPattern.firstMatch(rest[contentIndex].trim());

    // 「**本文：**」のように、見出しの飾りだけが残る場合は取り除く
    final sameLine = (contentMatch?.group(1) ?? '')
        .replaceFirst(RegExp(r'^[*#\s]+'), '');

    final contentLines = contentMatch == null
        ? rest
        : [
            if (sameLine.isNotEmpty) sameLine,
            ...rest.sublist(contentIndex + 1),
          ];

    return GeneratedDiary(
      title: title,
      content: contentLines.join('\n').trim(),
    );
  }

  // 「**タイトル**」「「タイトル」」のような飾りを取り除く
  String _stripDecoration(String text) {
    var result = text.trim();

    result = result.replaceAll(RegExp(r'^[*#\s]+|[*#\s]+$'), '');

    if (result.length >= 2 &&
        ((result.startsWith('「') && result.endsWith('」')) ||
            (result.startsWith('『') && result.endsWith('』')) ||
            (result.startsWith('"') && result.endsWith('"')))) {
      result = result.substring(1, result.length - 1);
    }

    return result.trim();
  }
}
