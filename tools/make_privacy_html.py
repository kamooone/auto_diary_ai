#!/usr/bin/env python3
"""プライバシーポリシーと利用規約の Web ページ(server/points_web/ の privacy.html・terms.html)を作る

文面は、アプリの中で見せているものと同じ assets/ のファイルを、そのまま使う。
(文面を2か所に書くと、食い違うため。直すのは、assets/ のファイルだけ)

  assets/privacy_policy.md → privacy.html
  assets/terms_of_use.md   → terms.html

  python3 tools/make_privacy_html.py           Webページを作り直す
  python3 tools/make_privacy_html.py --check   Webページが、最新の文面から作ったものか確かめる
                                               (古ければ、終了コード1)

文面を直したら、このスクリプトを動かして、できたWebページを S3 に上げる。
"""
import html
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
WEB = ROOT / "server" / "points_web"

# (文面, できるWebページ, 題)
DOCUMENTS = [
    (ROOT / "assets" / "privacy_policy.md", WEB / "privacy.html", "プライバシーポリシー"),
    (ROOT / "assets" / "terms_of_use.md", WEB / "terms.html", "利用規約"),
]

# 「情報の削除」の節には、ストアの申請(データの削除方法のページ)から、直接飛べるよう、目印を付ける
ANCHORS = {"情報の削除": "delete", "お問い合わせ": "contact"}

# Webページだけに足す案内(アプリの中の文面には、リンクを置けないため)
# 「情報の削除」の節の終わりに、アカウントの削除ができるページへのリンクを出す
EXTRAS = {
    "delete": (
        '      <p class="link"><a href="index.html">ポイントのページを開く</a>'
        "(ログインのあと、ページの一番下の「アカウントの削除」から削除できます)</p>"
    ),
}

TEMPLATE = """<!doctype html>
<html lang="ja">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{title} | あなたの軌跡</title>
  <link rel="icon" href="icon.png">
  <!-- このファイルは、tools/make_privacy_html.py が assets/privacy_policy.md から作る。直接は直さない -->
  <style>
    :root {{
      --navy: #3F5879; --navy-dark: #2E4260; --pink: #FFE4E1; --page: #FFF7F5; --white: #FFFFFF;
      --text: #1F2430; --text-sub: #5E6472; --line: #F0DAD5;
      --shadow: 0 1px 2px rgba(46, 66, 96, .06), 0 4px 12px rgba(46, 66, 96, .05);
    }}
    * {{ box-sizing: border-box; }}
    body {{ margin: 0; background: var(--page); color: var(--text);
           font-family: "Noto Sans JP", system-ui, -apple-system, "Hiragino Sans", sans-serif;
           font-size: 15px; line-height: 1.8; }}
    header {{ background: var(--navy); color: var(--white); height: 56px;
             display: flex; align-items: center; gap: 12px; padding: 0 16px; }}
    header img {{ width: 32px; height: 32px; border-radius: 8px; }}
    header .name {{ font-weight: 700; letter-spacing: .04em; }}
    main {{ max-width: 720px; margin: 0 auto; padding: 20px 16px 48px; }}
    .doc {{ background: var(--white); border-radius: 16px; box-shadow: var(--shadow); padding: 20px 20px 24px; }}
    h1 {{ font-size: 24px; margin: 0 0 8px; line-height: 1.4; }}
    h2 {{ font-size: 18px; margin: 32px 0 8px; padding-top: 16px; border-top: 1px solid var(--line);
         color: var(--navy-dark); line-height: 1.5; scroll-margin-top: 8px; }}
    p {{ margin: 8px 0; overflow-wrap: anywhere; }}
    ul {{ margin: 8px 0; padding-left: 22px; }}
    li {{ margin: 4px 0; overflow-wrap: anywhere; }}
    strong {{ color: var(--navy-dark); }}
    a {{ color: var(--navy-dark); font-weight: 700; }}
    .date {{ color: var(--text-sub); font-size: 13px; margin: 0; }}
  </style>
</head>
<body>
  <header>
    <img src="icon.png" alt="">
    <span class="name">あなたの軌跡</span>
  </header>
  <main>
    <article class="doc">
{body}
    </article>
  </main>
</body>
</html>
"""


def inline(text):
    """文中の **太字** を <strong> にする(それ以外の記号は、そのまま文字として出す)"""
    escaped = html.escape(text, quote=False)
    return re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", escaped)


def convert(markdown, title):
    """このポリシーで使っている書き方(見出し・箇条書き・段落・太字)だけを変換する"""
    out = []
    paragraph = []
    in_list = False
    anchor = None  # いま読んでいる節の目印

    def flush_paragraph():
        if paragraph:
            out.append("      <p>" + "<br>".join(inline(line) for line in paragraph) + "</p>")
            paragraph.clear()

    def close_list():
        nonlocal in_list
        if in_list:
            out.append("      </ul>")
            in_list = False

    def close_section():
        # 節の終わりに、その節だけの追加の案内があれば、出す
        flush_paragraph()
        close_list()
        if anchor in EXTRAS:
            out.append(EXTRAS[anchor])

    for raw in markdown.splitlines():
        line = raw.rstrip()

        if not line:
            flush_paragraph()
            close_list()
        elif line.startswith("# "):
            flush_paragraph()
            close_list()
            out.append(f"      <h1>{inline(line[2:])}</h1>")
        elif line.startswith("## "):
            close_section()
            heading = line[3:]
            anchor = next(
                (id_ for key, id_ in ANCHORS.items() if key in heading), None
            )
            attr = f' id="{anchor}"' if anchor else ""
            out.append(f"      <h2{attr}>{inline(heading)}</h2>")
        elif line.startswith("- "):
            flush_paragraph()
            if not in_list:
                out.append("      <ul>")
                in_list = True
            out.append(f"        <li>{inline(line[2:])}</li>")
        else:
            close_list()
            paragraph.append(line)

    close_section()

    body = "\n".join(out)
    # 「制定日」「最終改定日」の行は、目立たない色にする
    body = re.sub(
        r"<p>((?:制定日|最終改定日):[^<]*)</p>", r'<p class="date">\1</p>', body
    )
    return TEMPLATE.format(title=title, body=body)


def main():
    check = "--check" in sys.argv
    outdated = False

    for source, output, title in DOCUMENTS:
        result = convert(source.read_text(encoding="utf-8"), title)

        if check:
            current = output.read_text(encoding="utf-8") if output.exists() else ""
            if current != result:
                print(f"{output.name} が古いです。python3 tools/make_privacy_html.py で作り直してください。")
                outdated = True
            else:
                print(f"{output.name} は、最新です。")
        else:
            output.write_text(result, encoding="utf-8")
            print(f"作りました: {output.relative_to(ROOT)}")

    if outdated:
        sys.exit(1)


if __name__ == "__main__":
    main()
