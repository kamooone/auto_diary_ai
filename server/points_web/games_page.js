// ゲームの紹介ページ(games.html)。一覧は、games_data.js の window.GAMES から作る。
// 文字は、textContent で入れる(データに記号が入っていても、そのまま表示される)

function gameCard(game) {
  const card = document.createElement("div");
  card.className = "card game";

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
