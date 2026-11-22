// ゲームの紹介ページ(games.html)。一覧は、games_data.js の window.GAMES から作る。
// 文字は、textContent で入れる(データに記号が入っていても、そのまま表示される)

function gameCard(game) {
  const card = document.createElement("div");
  card.className = "card game";
  card.dataset.gameId = game.id;

  const head = document.createElement("div");
  head.className = "gameHead";

  // アイコン(画像がなければ、頭文字の丸)
  if (game.icon) {
    const img = document.createElement("img");
    img.className = "gameIcon";
    img.src = game.icon;
    img.alt = "";
    head.append(img);
  } else {
    const initial = document.createElement("div");
    initial.className = "gameIcon initial";
    initial.textContent = [...game.name][0] ?? "";
    head.append(initial);
  }

  const name = document.createElement("h3");
  name.textContent = game.name;
  head.append(name);
  card.append(head);

  const summary = document.createElement("p");
  summary.className = "gameSummary";
  summary.textContent = game.summary;
  card.append(summary);

  if (game.points) {
    const points = document.createElement("p");
    points.className = "gamePoints";
    points.textContent = game.points;
    card.append(points);
  }

  // ストアのページがあるときだけ、ボタンを出す
  if (game.storeUrl) {
    const link = document.createElement("a");
    link.className = "primary linkButton";
    link.href = game.storeUrl;
    link.target = "_blank";
    link.rel = "noopener";
    link.textContent = "Google Play で見る";
    card.append(link);
  }

  return card;
}

const list = document.getElementById("gameList");
const games = window.GAMES ?? [];

if (games.length === 0) {
  document.getElementById("gameEmpty").hidden = false;
} else {
  list.append(...games.map(gameCard));
}

// ---------- ポイントが貯まるケースの表
// ケースの一覧は、サーバー(GET /rules)から取る。ポイントの量や回数の上限は、
// サーバーのルールがそのまま出るため、ここには数字を書かない。

// 回数の上限の説明(上限がなければ空)
function limitText(event) {
  const parts = [];
  if (event.maxPerDay) parts.push(`1日${event.maxPerDay}回まで`);
  if (event.maxTotal) parts.push(`${event.maxTotal}回まで`);
  return parts.join("・");
}

// 表(ダイアログの中に入れる)
function rulesTable(game) {
  // 上限のあるケースが1つもなければ、「回数の上限」の列は出さない
  const hasLimit = game.events.some((e) => limitText(e));

  const table = document.createElement("table");
  const head = document.createElement("tr");
  for (const label of ["ケース", "ポイント"]) {
    const th = document.createElement("th");
    th.textContent = label;
    if (label === "ポイント") th.className = "num";
    head.append(th);
  }
  if (hasLimit) {
    const th = document.createElement("th");
    th.textContent = "回数の上限";
    head.append(th);
  }
  table.append(head);

  const yen = new Intl.NumberFormat("ja-JP");

  for (const event of game.events) {
    const row = document.createElement("tr");

    const name = document.createElement("td");
    name.textContent = event.label;

    const points = document.createElement("td");
    points.className = "num";
    points.textContent = yen.format(event.points);

    row.append(name, points);

    if (hasLimit) {
      const limit = document.createElement("td");
      limit.className = "limit";
      limit.textContent = limitText(event);
      row.append(limit);
    }

    table.append(row);
  }

  return table;
}

// 「ポイントが貯まるケースを見る」ボタン。押すと、ダイアログで表を出す
// (ゲームが増えても、ページが縦に長くならない)
function rulesButton(game) {
  const button = document.createElement("button");
  button.type = "button";
  button.className = "secondary";
  button.textContent = "ポイントが貯まるケースを見る";
  button.onclick = () => openRulesDialog(game);
  return button;
}

const rulesDialog = document.getElementById("rulesDialog");

function openRulesDialog(game) {
  document.getElementById("rulesTitle").textContent = game.name;
  document.getElementById("rulesBody").replaceChildren(rulesTable(game));

  // 古いブラウザなど、dialog が使えないときは、何もしない
  if (typeof rulesDialog.showModal !== "function") return;

  rulesDialog.showModal();
  // 裏のページが、一緒にスクロールしないようにする
  document.body.style.overflow = "hidden";
}

function closeRulesDialog() {
  if (rulesDialog.open) rulesDialog.close();
}

document.getElementById("rulesClose").onclick = closeRulesDialog;
// ダイアログの外(暗い部分)を押したときも、閉じる
rulesDialog.addEventListener("click", (event) => {
  if (event.target === rulesDialog) closeRulesDialog();
});
// 閉じたとき(Esc キーを含む)に、裏のスクロールを元に戻す
rulesDialog.addEventListener("close", () => {
  document.body.style.overflow = "";
});

async function loadRules() {
  const apiBase = window.APP_CONFIG?.apiBase;
  if (!apiBase) return;

  try {
    const response = await fetch(`${apiBase}/rules`);
    if (!response.ok) return;

    const { games: rules } = await response.json();

    for (const game of rules ?? []) {
      const card = list.querySelector(`[data-game-id="${CSS.escape(game.appId)}"]`);
      if (!card || !game.events?.length) continue;

      // ダイアログの題は、カードに出しているゲームの名前にする
      const title = card.querySelector("h3")?.textContent ?? game.name;

      // ストアのボタンがあれば、その前に入れる
      card.insertBefore(
        rulesButton({ ...game, name: title }),
        card.querySelector(".linkButton"),
      );
    }
  } catch {
    // 取得できなくても、ゲームの紹介は、そのまま表示される
  }
}

loadRules();
