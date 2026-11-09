"""AIに渡す、日記まわりのプロンプトを組み立てる(アプリではなく、サーバーが持つ)

アプリは、材料(行動履歴・Xの投稿・日記を文章にしたもの)と、設定(書き方・文字数の目安など)だけを送る。
指示の文章と、組み立ては、すべてここにある。プロンプトを直すときは、このファイルを直す。

  build_prompt(spec, photo_count)  ->  AIに渡す文章

spec(アプリが送る内容)の kind:
  "diary"              ふつうのAI日記
  "summary"            日記を1つにする
  "consult_first"      日記を1つにする書き方の相談(最初)
  "consult_follow_up"  同(続き)

注意: 回答の形式(「タイトル:」「本文:」、「【相談の回答】」など)は、アプリが解析している。
      形式の文言は変えないこと(変えると、アプリが回答を読み取れない)。
場所の対応表と変更履歴: docs/prompt_map.md、docs/prompt_history.md
"""
import math
import re


class PromptError(ValueError):
    """アプリから届いた内容が正しくないとき"""


# ---- 共通の部品 --------------------------------------------------------------

# 回答の形式(日記とまとめ日記に共通。アプリの解析と合わせてある)
ANSWER_MARKER = "【相談の回答】"
PROPOSAL_MARKER = "【書き方の指示】"
BRIEF_MARKER = "【材料メモ】"


def dart_round(value):
    """四捨五入(正の数。Dartの round() と同じく、.5は切り上げる)"""
    return int(math.floor(value + 0.5))


def clamp(value, low, high):
    return max(low, min(value, high))


def length_range(
    chars, low_ratio=0.10, high_ratio=0.15,
    min_low=300, max_low=6000, max_high=8000,
):
    """書いてほしい文章の長さの範囲(文字)。日記の文字数の、low_ratio〜high_ratio

    少なすぎると細部が残らず、多すぎると時間とトークンがかかるため、下限と上限を設ける
    """
    low = dart_round(clamp(chars * low_ratio, min_low, max_low) / 100) * 100
    high = dart_round(clamp(chars * high_ratio, low + 200, max_high) / 100) * 100

    return low, high


def length_guide(
    chars, low_ratio=0.10, high_ratio=0.15,
    min_low=300, max_low=6000, max_high=8000,
):
    """length_range を「○〜○文字」の文にしたもの"""
    low, high = length_range(
        chars, low_ratio, high_ratio, min_low, max_low, max_high
    )

    return f"{low}〜{high}文字"


ANSWER_FORMAT = """回答は必ず次の形式で書いてください。前置きや説明、記号による装飾は付けないでください。

タイトル: (日記のタイトルを1行で)
本文:
(日記の本文)
"""


# 複数日をまとめるときの共通ルール(まとめ日記と、ふつうの日記の複数日で使う)
SUMMARY_RULES = """・本人が書いた日記として、「私は〜」「〜した」のように、素直な言葉で書いてください。
・印象に残った出来事は、日付(○月○日)と具体的な内容(場所、人、食べたもの、したことなど)を入れて書いてください。「充実した日々だった」のような、誰の日記にも当てはまる一般的な言葉だけで済ませないでください。
・出来事を1日ずつ順に並べるのではなく、大きな出来事、何度も繰り返したこと、気持ちや状況の変化を選んでまとめてください。同じことが何度もあった場合は、「何度も」「ほぼ毎日」のように頻度で触れてください。
・時間の流れに沿って、前半と後半の違いなど、変化がわかるように書いてください。
・「心温まる」「ささやかな幸せ」「噛み締める」のような、飾りの多い決まり文句は避けてください。
・渡された情報に書かれていないことや、そこから読み取れない気持ちは、書かないでください。"""


# ---- 型のチェック ------------------------------------------------------------

def _text(spec, key, default=""):
    value = spec.get(key, default)

    if value is None:
        return default

    if not isinstance(value, str):
        raise PromptError(f"{key} must be a string")

    return value


def _int(spec, key, default=0):
    value = spec.get(key, default)

    if isinstance(value, bool) or not isinstance(value, int) or value < 0:
        raise PromptError(f"{key} must be a non-negative integer")

    return value


def _date(spec, key):
    value = _text(spec, key)
    matched = re.fullmatch(r"(\d{4})-(\d{2})-(\d{2})", value)

    if not matched:
        raise PromptError(f"{key} must be yyyy-MM-dd")

    return int(matched[1]), int(matched[2]), int(matched[3])


def _date_text(date):
    year, month, day = date
    return f"{year}年{month}月{day}日"


def _period(start, end):
    if start == end:
        return _date_text(start)

    return f"{_date_text(start)}〜{_date_text(end)}"


# ---- ふつうのAI日記 ----------------------------------------------------------

DIARY_STYLES = ["diary", "blog", "record", "bullets", "custom"]

# 時系列の記録と箇条書きで、複数日のときに足す注意
_MULTI_DAY_NOTE = """

複数日の情報のときの注意(必ず守ってください)
・渡した情報の期間の全体を、最初の日から最後の日まで、日ごとに書いてください。最後の日だけの記録にしないでください。タイトルも、最後の日ではなく、期間に合わせてください(「○月○日〜○月○日の記録」など)。
・情報のある日は、どの日も省かないでください。情報のない日は、書かないでください。
・期間が長いときは、1日あたり1〜3行にまとめ、大きな出来事を優先してください。"""


def _diary_style_diary(is_multi_day):
    multi = ""

    if is_multi_day:
        multi = (
            "\n\n複数日の情報をまとめた日記を書くときの書き方\n"
            + SUMMARY_RULES
            + "\n・渡した期間が数日(1週間ほどまで)のときは、情報のある日を、どの日も省かずに、日付を添えて書いてください(上の「1日ずつ順に並べない」より、この指示を優先します)。行動履歴の場所や滞在も、細部として本文に入れてください。"
        )

    return (
        "書き方(日記)\n"
        "写真の内容と行動履歴も照らし合わせて、時系列に沿った自然な日記を作成してください。"
        + multi
    )


def _diary_style_blog(is_multi_day):
    multi = ""

    if is_multi_day:
        multi = (
            "\n\n複数日の情報をまとめるときの注意(必ず守ってください)\n"
            "・渡した情報の期間の全体を、最初から最後まで書いてください。最後の日や、1日だけの話にしないでください。「今週」「今日」のような、1日や1週間だけの書き出しにせず、期間(「○月から○月」など)に合わせてください。\n"
            "・期間が長いときは、月や季節ごとの見出しを付け、見出しごとに、その時期の大きな出来事を、日付と具体的な内容(場所、人、食べたもの)を入れて書いてください。何度も繰り返したことは、頻度で触れてください。\n"
            "・行動履歴の場所や、Xの投稿の内容も、細部として本文に入れてください。"
        )

    return (
        """書き方(ブログ風)
・ブログ記事のように、読み物として書いてください。材料の量に合わせて、導入、見出し、終わりの一言を入れてください。見出しは、本文中に「1. 見出し」の形で書き、#や*などの記号は使わないでください。材料が少ないときは、見出しをつけずに書いてください。
・写真の内容と行動履歴も照らし合わせて、場所、人、食べたものなどの具体的な細部を入れてください。
・複数日の情報のときは、日付ごとに区切るのではなく、旅行記のように、流れで書いてください。大きな出来事には、「○月○日」と日付を添えてください。
・本人が書いたブログとして、「私は〜」「〜した」のように、素直な言葉で書いてください。"""
        + multi
    )


def _diary_style_record(is_multi_day):
    return (
        """書き方(時系列の記録)
・時刻の順に、出来事を淡々と記録してください。行動履歴とXの投稿の時刻を手がかりに、「9:00 駅に到着」のように、時刻と出来事を1行ずつ並べてください。
・時刻が分からない出来事(写真に写っているものなど)は、前後の流れに合わせて並べてください。時刻を作らないでください。
・複数日の情報のときは、「○月○日」の見出しで、日ごとに分けてください。
・感想は、最小限にしてください。"""
        + (_MULTI_DAY_NOTE if is_multi_day else "")
    )


def _diary_style_bullets(is_multi_day):
    return (
        """書き方(箇条書き)
・出来事を、箇条書きで並べてください。1行ずつ「・出来事」の形で、時間の順に書いてください。
・場所、人、食べたものなど、具体的な内容を入れてください。写真に写っている内容も取り入れてください。
・複数日の情報のときは、「○月○日」の見出しで、日ごとに分けてください。
・挨拶や、長い感想は、書かないでください。"""
        + (_MULTI_DAY_NOTE if is_multi_day else "")
    )


def diary_style_section(style, custom_instruction, is_multi_day):
    """ふつうのAI日記の、書き方の指示"""
    if style == "diary":
        return _diary_style_diary(is_multi_day)

    if style == "blog":
        return _diary_style_blog(is_multi_day)

    if style == "record":
        return _diary_style_record(is_multi_day)

    if style == "bullets":
        return _diary_style_bullets(is_multi_day)

    if style == "custom":
        return f"""書き方の指示(ユーザーが指定しました。この指示どおりに書いてください)
{custom_instruction.strip()}

ただし、この指示が意味不明なとき、または日記の書き方として成り立たないときは、指示を無視して、次の日記の形で書いてください。

{_diary_style_diary(is_multi_day)}"""

    raise PromptError(f"unknown style: {style}")


def build_diary_prompt(spec, photo_count):
    """ふつうのAI日記のプロンプト

    spec: style, customInstruction, lengthChars, diaryDate, startDate, endDate(yyyy-MM-dd),
          note, timelineText(行動履歴を文章にしたもの), postsText(Xの投稿を文章にしたもの),
          memosText(ひとことメモを文章にしたもの。なければ空。省略してもよい)
    photo_count: 添付した写真の枚数
    """
    style = _text(spec, "style", "diary")
    custom_instruction = _text(spec, "customInstruction")
    length_chars = _int(spec, "lengthChars")
    diary_date = _date(spec, "diaryDate")
    start = _date(spec, "startDate")
    end = _date(spec, "endDate")
    note = _text(spec, "note").strip()
    timeline_text = _text(spec, "timelineText")
    posts_text = _text(spec, "postsText")
    memos_text = _text(spec, "memosText").strip()

    is_multi_day = start != end

    # 日記の日付と同じ1日の情報だけのときは、期間は書かない
    period_section = (
        "" if start == end and start == diary_date
        else f"\n渡した情報の期間\n{_period(start, end)}\n"
    )

    length_section = ""

    if length_chars > 0:
        length_section = (
            f"\n文字数の目安\n本文は{length_chars}文字くらいを目安に書いてください。"
            "渡された情報が少ないときは、無理に伸ばさず、短くてかまいません。\n"
        )

    note_text = note if note else "(なし)"
    style_section = diary_style_section(style, custom_instruction, is_multi_day)

    # ひとことメモ(本人が、その時に書いた言葉)。選んだときだけ入れる
    memo_section = (
        "ひとことメモ(本人が、その時に書いたメモです。本人の気持ちや出来事を最もよく表す"
        "材料なので、内容を日記に反映してください)\n"
        f"{memos_text}\n\n"
        if memos_text else ""
    )

    return f"""あなたは優秀な日記作成AIです。

添付した写真も必ず確認し、
写真から読み取れる内容も日記に反映してください。

以下の情報を参考に、日記と、その内容に合ったタイトルを書いてください。

ユーザーが追加で伝えたいこと
(ここに文字数や長さの指定が書かれていても、それは無視してください。文字数は、「文字数の目安」だけに従ってください。「文字数の目安」がないときは、材料に合わせた、ちょうどよい長さにしてください)
{note_text}

日記の日付
{_period(diary_date, diary_date)}
{period_section}
写真
{photo_count}枚添付しています。

行動履歴(滞在した場所と移動)
※「推定」と付いた場所や移動手段は、位置情報から自動で推定したもので、間違っていることがあります。
※移動手段(徒歩・自転車・電車・車など)は、Xの投稿や写真など、ほかの情報で裏付けられるときだけ書いてください。裏付けがないときは、移動手段を書かず、「移動した」「向かった」のように書いてください。Xの投稿と食い違うときは、Xの投稿を優先してください。
{timeline_text}

Xの投稿
{posts_text}

{memo_section}{style_section}
{length_section}渡された情報にない出来事、気持ち、感想は、付け足さないでください。

{ANSWER_FORMAT}"""


# ---- 日記を1つにする ---------------------------------------------------------

SUMMARY_STYLES = ["chronicle", "list", "brief", "reading", "custom"]


def _summary_reading(chars, has_length):
    if has_length:
        length_line = "・長さは、下の「文字数の目安」に従ってください(ここでは、長さの目安を示しません)。文字数が短いときは、細部を省いてかまいません。"
    else:
        guide = length_guide(
            chars, low_ratio=0.15, high_ratio=0.25,
            min_low=500, max_low=8000, max_high=12000,
        )
        length_line = f"・長さの目安は{guide}です。目安の下限より短くならないようにしてください。足りないときは、省略した出来事の細部を書き足してください。"

    return f"""形(読み物・ブログ風)
簡単なブログ風(大事なところだけを書いて、ほかは省略する形)とは違い、省略した細かい出来事も、省略せずに、できるだけ詳しく、ブログのような文章で書く形です。
材料を読んで、一番読みやすい構成を判断してください。
・5件以下のとき、または似た出来事の繰り返しが中心で内容に幅がないときは、章立てにせず、日付の流れに沿った1本の文章にしてください。繰り返しは、「何度も」「ほぼ毎日」のように頻度でまとめてください。
・仕事、旅行、趣味、人付き合いなど、性格の違う出来事が混ざっているときは、テーマごとの章立てにしてください。章は、内容から自然に分かれる2〜6個にして、無理に作らないでください。章の見出しは、本文中に「1. 見出し」の形で書き、#や*などの記号は使わないでください。
・章立てにしても、章の中は時間の流れに沿って書いてください。

書き方
・日記に書かれた出来事は、小さなものも省略せずに、できるだけ多く取り上げてください。場所、人、食べたもの、したこと、見たもの、気持ちなどの具体的な細部を、残してください。
・ブログのように、読み物らしい自然な文章で書いてください。出来事と出来事をつなげて、前後の流れや、気持ちの動きが分かるようにしてください(日記に書かれている範囲で)。
・いつの出来事かは、文章の中に自然に織り込んでください(「1月15日には」「上旬は」「連休中は」「その翌日」など)。各章に、日付か時期を、少なくとも1つは入れてください。章の中の出来事には、できるだけ時期(月、上旬・中旬・下旬、連休中など)を添えてください。「1月1日、〜。1月2日、〜。」のように、日付を先頭に付けた文を並べる書き方は避けてください。
・本人が書いたブログとして、「私は〜」「〜した」のように、素直な言葉で書いてください。元の日記の口調や言い回しも引き継いでください。
・材料の日記が複数の月にわたるときは、どの段落も、最初の文で、その段落の出来事の月を示してください(「4月は」「5月の連休には」「6月に入ると」など)。「この期間中」「別の日」のような、時期が分からない言い方だけで始めないでください。
・章立てにしたときは、1つの章を、2〜4文ごとの段落に分けて、段落と段落の間は、1行空けてください。1つの段落が5文以上になるときは、分けてください。章の中では、日付や時期が前に戻らないように、古いものから順に書いてください。
・「〜たり、〜たり、〜たりした」のような羅列にしないでください。つながりのある文で書いてください。1つの文に並べる出来事は、多くても3つまでにしてください。
・同じことの繰り返しだけは、まとめてかまいません。ただし、「ほぼ毎日」「毎日」「毎日のように」「日課」「習慣」「いつも」という言葉は、使わないでください(回数を正確に数えられないため)。同じ出来事が何日かに書かれているときだけ、「何度か」「たびたび」「ときどき」を使ってかまいません。1回しか書かれていない出来事には、頻度の言葉を使わないでください。
・「日記に書いた」「日記に記していた」のように、日記そのものに触れる言い方は、しないでください。本人が、そのときの出来事を直接書く形にしてください。
・意味が通る、自然な文にしてください。元の日記の複数の文を、無理につなげて、意味が分からない文にしないでください。
・「■」の日付と、その日記に書かれていることを、取り違えないでください。日記に書かれていない出来事や気持ちは、足さないでください。
{length_line}"""


def _summary_brief(chars):
    guide = length_guide(
        chars, low_ratio=0.03, high_ratio=0.05,
        min_low=200, max_low=1000, max_high=1500,
    )

    return f"""形(読み物・簡単なブログ風)
読み物(ブログ風)を、もっと簡潔にした形です。
・印象に残った出来事を選んで、いつの出来事か分かるように、「○月○日」と日付を添えて書いてください。日付が一日に決められない出来事(何度もあったこと)は、「1月上旬」「毎週のように」のように、時期や頻度で示してください。
・材料に合わせて、読みやすい並べ方を選んでください。時間の順に書いても、テーマ(仕事、趣味など)ごとにまとめてもかまいません。ただし、どの段落にも、「○月○日」と日付を添えた出来事を、1つ以上入れてください。
・段落に分けて、1つの段落は、2〜4文にして、段落と段落の間は、1行空けてください。見出しは付けないでください。
・日付は、古いものから順に並べてください(段落の順も、段落の中も、日付が前に戻らないようにしてください)。
・「■」の日付と、その日記に書かれていることを、取り違えないでください。日付を添えた出来事は、その日の日記に書かれていることだけにして、別の日の出来事を混ぜないでください。
・細かい出来事や、同じことの繰り返しは省いてかまいません。
・日記に書かれていない気持ち(驚いた、悲しかった、など)は、推測して書かないでください。
・本人が書いた日記として、「私は〜」「〜した」のように、素直な言葉で書いてください。
・長さの目安は{guide}です。"""


_SUMMARY_LIST = """形(出来事の一覧)
・文章ではなく、出来事の一覧にしてください。1つの日記につき、主な出来事を1〜2行にまとめて、日付の古い順に並べてください。
・1行ずつ「・○月○日 出来事」の形で書いてください。場所、人、食べたものなど、具体的な内容を入れてください。
・「■」の日付と、その日記に書かれていることを、取り違えないでください。その日の日記に書かれていないことは、書かないでください(別の日の出来事を混ぜないでください)。
・毎日のように似た出来事が続く日記でも、その日にしかない、ふだんと違う出来事を優先して選んでください。
・日記の件数と同じ数の行になるようにしてください(日記1つにつき1行。大きな出来事が複数ある日だけ、2行にしてかまいません)。
・章の見出し、挨拶、感想は、書かないでください。"""


def _summary_custom(custom):
    return f"""書き方の指示(ユーザーが指定しました。最優先です)
{custom.strip()}

この指示の守り方
・長さ、取り上げる内容の範囲(「仕事のことだけ」など)、口調、形(箇条書き、日付つきなど)は、指示に書かれていることを、必ず守ってください。指示に合わない出来事は、省いてください。
・長さの指示があるときは、その長さに収めてください。長さの指示がないときは、材料に合わせて、ちょうどよい長さにしてください。
・指示に書かれていない点(口調など)だけ、日記の口調に合わせて、自然に決めてください。
・文章で書くときの基本(指示にこれと違うことが書かれていれば、指示を優先してください): 2〜4文ごとに段落を分けて、段落と段落の間は1行空けてください(章立てのときは、章の中でも分けてください)。出来事には、いつごろかが分かるように、日付か時期(「1月15日には」「上旬は」「連休中は」など)を添えて、古いものから順に書いてください。箇条書きや、一覧の形のときは、この基本は使いません。
・指示に合う出来事が材料に少ないときは、無理に付け足さずに、あるものだけで書いてください。

例外: 指示が意味不明なとき、または日記を1つにする文章の書き方として成り立たないときだけ、指示を無視して、材料の日記を、日付の流れに沿った読みやすいブログ風の文章にしてください。必要なら、「1. 見出し」の形の章に分けてかまいません。長さは、材料の日記の合計の2割くらいにしてください。"""


def _summary_style(style, chars, custom, has_length):
    if style in ("reading", "chronicle"):
        # 日記を連結させるは、AIを使わずにつなげる(アプリ側)ので、ここには来ない。念のため読み物にする
        return _summary_reading(chars, has_length)

    if style == "brief":
        return _summary_brief(chars)

    if style == "list":
        return _SUMMARY_LIST

    if style == "custom":
        return _summary_custom(custom)

    raise PromptError(f"unknown style: {style}")


def _summary_final_check(style, chars, length_chars):
    """日記の材料のあとに置く、書く前の最終確認

    材料が長いと、先頭にある「形」の規則が守られにくいため、材料の後ろにも、守ってほしい点を繰り返す。
    長い文章で書く形(読み物・ブログ風)だけ。ほかの形は、規則が短く、守られている
    """
    if style not in ("reading", "chronicle"):
        return ""

    # 文字数の目安を指定したときは、それだけに合わせる(下限の数字と食い違うと、中途半端な長さになる)
    has_length = length_chars > 0

    low, high = length_range(
        chars, low_ratio=0.15, high_ratio=0.25,
        min_low=500, max_low=8000, max_high=12000,
    )

    if has_length:
        cover = "・文字数が短いときは、印象に残った出来事を選んでかまいません。ただし、期間の最初から最後まで、全体に触れてください(終わりの月ほど薄くならないようにしてください)。"
        length = f"・長さは、上の「文字数の目安」({length_chars}文字くらい)に合わせてください。形の説明にある長さの目安は、使わないでください。"
    else:
        cover = "・材料のどの時期も、省かずに取り上げてください(終わりの月ほど薄くならないようにしてください)。"
        length = f"・長さは、本文だけで、少なくとも{low}文字にしてください(目安は{low}〜{high}文字)。短くまとめすぎず、章や月ごとの段落でも、省略した出来事の細部を書き足してください。"

    return f"""書く前の最終確認(上の「形」の規則を守ってください。次の点は、特に忘れやすいです)
・1つの段落は、2〜4文にしてください。5文以上になるときは、分けてください。
・出来事を、短い文で並べるだけにしないでください。前後のつながりや、気持ちの動き(日記に書かれている範囲で)が分かる文章にしてください。
・同じ出来事や、同じ言い回しを、何度も書かないでください。繰り返された出来事は、「何度か」「たびたび」「ときどき」でまとめて、1回だけ書いてください。
・「ほぼ毎日」「毎日」「毎日のように」「日課」「習慣」「いつも」は、使わないでください。
・日記にない気持ち、決意、感想は、足さないでください。最後の段落も、日記に書かれた出来事で終えてください。
{cover}
・章の見出しは、章の中身に合う言葉にしてください。タイトルは、材料の期間(何月から何月までか)に合わせてください。
{length}
"""


def build_summary_prompt(spec):
    """日記を1つにするプロンプト

    spec: style, customInstruction, lengthChars, note, diaryCount,
          diariesText(日記を「■日付 タイトル 本文」で並べたもの), diariesChars(日記の文字数の合計)
    """
    style = _text(spec, "style", "reading")
    custom = _text(spec, "customInstruction")
    length_chars = _int(spec, "lengthChars")
    note = _text(spec, "note").strip()
    count = _int(spec, "diaryCount")
    diaries_text = _text(spec, "diariesText")
    chars = _int(spec, "diariesChars")

    has_length = length_chars > 0 and style != "list"
    style_section = _summary_style(style, chars, custom, has_length)

    length_section = ""

    if has_length:
        length_section = (
            f"\n文字数の目安\n本文は{length_chars}文字くらいを目安に書いてください"
            "(この指定は、上の形の長さの指示より優先してください)。"
            "材料が少ないときは、無理に伸ばさず、短くてかまいません。\n"
        )

    note_text = note if note else "(なし)"
    final_check = _summary_final_check(style, chars, length_chars)

    return f"""あなたは、日記を書いた本人になりきって文章を書くAIです。

以下は、ユーザー本人が書いた{count}件の日記です(日付の古い順)。
これらを材料に、この期間を1つの日記にした文章を書いてください。あわせて、その内容に合ったタイトルも書いてください。

{style_section}
{length_section}

共通のルール
・元の日記にない出来事、気持ち、感想は、付け足さないでください。
・全体を振り返る感想や、「充実した日々だった」のような決まり文句は、書かないでください。今後の決意や抱負(「明日も〜しようと思う」など)で締めることも、しないでください。最後の段落も、日記に書かれた出来事で終えてください。
・下の「ユーザーが追加で伝えたいこと」があれば、形や、取り上げる内容については、それを最優先してください。ただし、そこに文字数や長さの指定が書かれていても、それは無視してください(長さは、上の「文字数の目安」があればそれに、なければ上の形の長さの指示に従ってください)。

ユーザーが追加で伝えたいこと
{note_text}

日記(「■」から次の「■」までが、1つの日記です)
{diaries_text}
{final_check}
{ANSWER_FORMAT}"""


# ---- 書き方の相談 ------------------------------------------------------------

_CONSULT_ROLE = """あなたは、日記アプリの「日記を1つにする」機能の、書き方の相談役です。
この機能は、ユーザーが選んだ作成済みの日記を材料に、別のAIが1つの日記を書きます。
あなたが提案した「書き方の指示」は、ユーザーが画面のボタンを押すと、自動で「自分で指定」の欄に入り、別のAIに渡されます。
書き方の種類の例(参考です。この文をそのまま写さないでください。ユーザーには、番号や名前を出して「選んでください」と言わないでください):
・出来事の一覧(日付ごとの出来事を箇条書きで並べる形)
・簡潔な読み物(印象に残った出来事だけを選んで、日付つきで短く書く形)
・詳しい読み物(章立てして、細かい出来事も省略せずに、ブログのように書く形)
どの書き方が合うときも、「書き方の指示」には、この材料に合わせた具体的な内容を書いてください。ユーザーに、指示を入力させたり、書き方を選ばせたりする言い方は、しないでください。
(このほかに、AIを使わずに日記を日付順にそのままつなげる機能もありますが、これは相談では提案しません)"""

_CONSULT_TASK = """ユーザーの相談に乗って、材料に合った書き方を提案してください。
・日記の書き方の相談以外には、答えません。関係のない話には、その旨を短く伝えて、書き方の相談に戻してください。
・日記にないことを書き足すことはできません。写真や画像は扱えません。
・提案する書き方の指示は、あとで別のAIに、そのまま渡す文章です。「自分で指定」の欄にそのまま入れられるように、具体的に、3〜5文で書いてください。次の内容を、材料に合わせて入れてください。
  - 形(文章か、箇条書きか)と、章立てにするときは、この材料に合った章のテーマの名前(例: 「仕事」「趣味」「食事」)
  - 長さの目安(文字数)
  - 口調(日記の口調に合わせる、です・ます調、など)
  - 文章のときは、段落を分けることと、出来事に日付や時期を添えること
  - 残したい内容や、省いてよい内容(あれば)
  - ユーザーがタイトルについて希望を言ったときは、その希望も入れてください(ただし、「日記の内容から外れない範囲で」と添えてください)
・ユーザーが複数の案を求めたときは、返答の文章で、2〜3案を、1案につき1文で短く紹介してください。そのうえで、いちばん合う1つだけを、書き方の指示として出してください。ほかの案を使いたいときは、案の名前を言って伝えてもらうよう、案内してください。
・材料に含まれない話題や、日記に書かれていない気持ちを足すような指示は、入れないでください。
・「次の指示を入力してください」「○番を選んでください」のような言い方は、しないでください。提案を出したら、「この書き方でよければ、下のボタンで使えます」と伝えるだけにしてください。
・やさしい言葉で、短く答えてください。"""

_CONSULT_FORMAT = f"""回答は必ず次の形式で書いてください。
{ANSWER_MARKER}
(ユーザーに見せる文章)
{PROPOSAL_MARKER}
(提案する書き方の指示だけを書く。説明や前置きは書かない。提案しないときは、この見出しごと書かない)"""


def build_consult_first_prompt(spec):
    """書き方の相談(最初)のプロンプト。日記の全文を渡す

    spec: diaryCount, diariesText(日記を「日付 タイトル 本文」で並べたもの)
    """
    count = _int(spec, "diaryCount")
    diaries_text = _text(spec, "diariesText")

    return f"""{_CONSULT_ROLE}

ユーザーが選んだ{count}件の日記です(日付の古い順)。
{_CONSULT_TASK}

最初に、日記を読んで、材料の特徴(テーマの幅、出来事の種類、繰り返しの多さ、全体の量など)を2〜4文で伝えてから、おすすめの書き方を提案してください。

{_CONSULT_FORMAT}
{BRIEF_MARKER}
(これからの相談で、日記の全文の代わりに使う、材料の分析メモ。テーマ、出来事の種類、繰り返し、特徴、期間、件数を、500文字以内で書く)

日記
{diaries_text}
"""


def build_consult_follow_up_prompt(spec):
    """書き方の相談(続き)のプロンプト。日記の全文は渡さず、材料メモと会話だけを渡す

    spec: brief, history([{fromUser, text, proposal}]), message
    """
    brief = _text(spec, "brief")
    message = _text(spec, "message")
    history = spec.get("history", [])

    if not isinstance(history, list):
        raise PromptError("history must be a list")

    lines = []

    for item in history:
        if not isinstance(item, dict):
            raise PromptError("history item must be an object")

        proposal = item.get("proposal")
        proposal_text = (
            f"\n(提案した書き方の指示: {proposal})" if proposal is not None else ""
        )
        speaker = "ユーザー" if item.get("fromUser") is True else "あなた"
        lines.append(f"{speaker}: {_text(item, 'text')}{proposal_text}")

    talk = "\n".join(lines)

    return f"""{_CONSULT_ROLE}

{_CONSULT_TASK}

材料の分析メモ(最初に日記を読んで作ったものです。日記の全文は、もう渡しません)
{brief}

ここまでの相談
{talk}

ユーザーの新しい発言
{message}

ユーザーの発言に答えてください。書き方の提案を変える、または新しく出すときは、{PROPOSAL_MARKER} も書いてください。質問に答えるだけのときは、{PROPOSAL_MARKER} は書かないでください。

{_CONSULT_FORMAT}
"""


# ---- 回答の判定 --------------------------------------------------------------

# 日記・日記を1つにするの回答(「タイトル:」「本文:」の形式)
_TITLE_PATTERN = re.compile(r"^[#*\s]*タイトル[*\s]*[:：]\s*(.*)$")
_CONTENT_PATTERN = re.compile(r"^[#*\s]*本文[*\s]*[:：]\s*(.*)$")

# 回答が日記の形式のプロンプト
DIARY_ANSWER_KINDS = ("diary", "summary")


def diary_answer_content(answer):
    """日記の回答から、本文を取り出す(アプリの GeneratedDiaryParser と、同じ規則)

    指示どおりの形式でなかったときは、回答全体を本文とする。
    本文が空かの判定にだけ使う(サーバーは、本文を加工して返さない)。
    アプリの解析(lib/.../generated_diary_parser.dart)を変えたら、ここも合わせること
    """
    lines = answer.strip().split("\n")

    title_index = next((i for i, line in enumerate(lines) if line.strip()), -1)
    title_match = (
        _TITLE_PATTERN.match(lines[title_index].strip()) if title_index >= 0 else None
    )

    if title_match is None:
        return answer.strip()

    rest = lines[title_index + 1:]
    content_index = next((i for i, line in enumerate(rest) if line.strip()), -1)
    content_match = (
        _CONTENT_PATTERN.match(rest[content_index].strip())
        if content_index >= 0 else None
    )

    if content_match is None:
        content_lines = rest
    else:
        same_line = re.sub(r"^[*#\s]+", "", content_match.group(1) or "")
        content_lines = ([same_line] if same_line else []) + rest[content_index + 1:]

    return "\n".join(content_lines).strip()


def is_empty_diary_answer(spec, answer):
    """日記の回答で、本文が空かどうか(空なら、失敗として扱い、トークンを使わせない)

    日記・日記を1つにする以外(相談など)は、見ない
    """
    if not isinstance(spec, dict) or spec.get("kind") not in DIARY_ANSWER_KINDS:
        return False

    return not diary_answer_content(answer)


# ---- 入口 --------------------------------------------------------------------

def build_prompt(spec, photo_count=0):
    """アプリが送った spec から、AIに渡す文章を組み立てる"""
    if not isinstance(spec, dict):
        raise PromptError("prompt must be an object")

    kind = spec.get("kind")

    if kind == "diary":
        return build_diary_prompt(spec, photo_count)

    if kind == "summary":
        return build_summary_prompt(spec)

    if kind == "consult_first":
        return build_consult_first_prompt(spec)

    if kind == "consult_follow_up":
        return build_consult_follow_up_prompt(spec)

    raise PromptError(f"unknown kind: {kind}")
