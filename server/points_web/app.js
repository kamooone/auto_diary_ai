// Cognito のホストUIを使った、ログインの処理(Authorization Code + PKCE)
//
// 流れ
//   1. 「ログイン」を押す → Cognito のログイン画面へ移動する
//   2. ログインが終わると、このページに ?code=... をつけて戻ってくる
//   3. そのcodeを、Cognito に渡して、トークン(許可証)と交換する
//   4. トークンの中のメールアドレスを、画面に表示する
//
// PKCE: 戻ってきたcodeを、別の誰かに横取りされても使えないようにする仕組み。
//       ログイン前に作った「合言葉(verifier)」を、交換のときに一緒に送る。

const { cognitoDomain, clientId, apiBase } = window.APP_CONFIG;

// ログイン後に戻ってくるURL(Cognito のアプリクライアントに登録した値と、完全に同じにする)
const redirectUri = location.origin + location.pathname;

const els = {
  signedOut: document.getElementById("signedOut"),
  signedIn: document.getElementById("signedIn"),
  email: document.getElementById("email"),
  points: document.getElementById("points"),
  tokens: document.getElementById("tokens"),
  notice: document.getElementById("notice"),
  exchangeRule: document.getElementById("exchangeRule"),
  exchangePoints: document.getElementById("exchangePoints"),
  exchangeHint: document.getElementById("exchangeHint"),
  pairingCode: document.getElementById("pairingCode"),
  deviceCount: document.getElementById("deviceCount"),
  deviceList: document.getElementById("deviceList"),
  historyList: document.getElementById("historyList"),
  historyEmpty: document.getElementById("historyEmpty"),
  historyMore: document.getElementById("historyMoreButton"),
  message: document.getElementById("message"),
  deleteIntro: document.getElementById("deleteIntro"),
  deleteForm: document.getElementById("deleteForm"),
  deleteConfirm: document.getElementById("deleteConfirm"),
  deleteEmail: document.getElementById("deleteEmail"),
};

// ---------- 小さな道具

function base64Url(bytes) {
  return btoa(String.fromCharCode(...new Uint8Array(bytes)))
    .replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function randomString() {
  return base64Url(crypto.getRandomValues(new Uint8Array(48)));
}

async function sha256(text) {
  return crypto.subtle.digest("SHA-256", new TextEncoder().encode(text));
}

// JWT(トークン)の真ん中の部分を、読み取る。表示のためだけで、本物かどうかの確認はしない。
// (本物かどうかは、サーバー側(API Gateway)が確認する)
function readJwt(token) {
  const payload = token.split(".")[1].replace(/-/g, "+").replace(/_/g, "/");
  const bytes = Uint8Array.from(atob(payload), (c) => c.charCodeAt(0));
  return JSON.parse(new TextDecoder().decode(bytes));
}

function show(message) {
  els.message.textContent = message;
  els.notice.textContent = "";
}

function showNotice(message) {
  els.notice.textContent = message;
  els.message.textContent = "";
}

const yen = new Intl.NumberFormat("ja-JP");

// ---------- ログイン

// forceLogin: true なら、ログインしたままでも、パスワードの入力をもう一度求める(アカウントの削除のとき)
async function login({ forceLogin = false } = {}) {
  const verifier = randomString();
  const state = randomString();

  // 戻ってきたときに使うので、ブラウザ(このタブ)に預けておく
  sessionStorage.setItem("pkce_verifier", verifier);
  sessionStorage.setItem("oauth_state", state);

  const params = new URLSearchParams({
    response_type: "code",
    client_id: clientId,
    redirect_uri: redirectUri,
    scope: "openid email",
    state,
    code_challenge: base64Url(await sha256(verifier)),
    code_challenge_method: "S256",
    // ログイン画面の言葉を、日本語にする
    lang: "ja",
    ...(forceLogin ? { prompt: "login" } : {}),
  });

  location.href = `${cognitoDomain}/oauth2/authorize?${params}`;
}

// ログインから戻ってきたとき: codeをトークンに交換する
async function handleCallback(code, state) {
  const verifier = sessionStorage.getItem("pkce_verifier");

  if (!verifier || state !== sessionStorage.getItem("oauth_state")) {
    throw new Error("ログインの状態が一致しません。もう一度ログインしてください。");
  }

  const response = await fetch(`${cognitoDomain}/oauth2/token`, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "authorization_code",
      client_id: clientId,
      code,
      redirect_uri: redirectUri,
      code_verifier: verifier,
    }),
  });

  if (!response.ok) {
    throw new Error(`トークンを取得できませんでした (${response.status})`);
  }

  const tokens = await response.json();
  sessionStorage.setItem("id_token", tokens.id_token);
  // APIを呼ぶときの許可証。メールアドレスなどの表示用の情報は、id_tokenにある
  sessionStorage.setItem("access_token", tokens.access_token);
  sessionStorage.removeItem("pkce_verifier");
  sessionStorage.removeItem("oauth_state");

  // URLから ?code=... を消す(再読み込みで、同じcodeを使わないように)
  history.replaceState(null, "", redirectUri);
}

function logout() {
  sessionStorage.clear();

  const params = new URLSearchParams({
    client_id: clientId,
    logout_uri: redirectUri,
  });

  location.href = `${cognitoDomain}/logout?${params}`;
}

// ---------- ポイントのAPI

// ログイン中のアカウントとして、APIを呼ぶ
async function callApi(method, path, body) {
  const response = await fetch(`${apiBase}${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${sessionStorage.getItem("access_token")}`,
      "Content-Type": "application/json",
    },
    body: body ? JSON.stringify(body) : undefined,
  });

  if (response.status === 401) {
    // 許可証の期限切れ。ログインし直してもらう
    sessionStorage.clear();
    throw new Error("ログインの期限が切れました。もう一度ログインしてください。");
  }
  const data = await response.json().catch(() => ({}));

  if (!response.ok) {
    // サーバーが返した理由を、分かりやすい言葉にする
    const messages = {
      below_minimum: `${yen.format(data.minPoints ?? 0)}ポイント以上から交換できます。`,
      insufficient_points: "ポイントが足りません。",
      invalid_points: "ポイントは、1以上の整数で入力してください。",
      request_id_conflict: "同じ操作が重複しました。もう一度お試しください。",
      invalid_code: "コードが正しくないか、期限が切れています。アプリで新しいコードを表示してください。",
      device_limit: `同じアプリに紐づけられる端末は${data.maxDevices ?? ""}台までです。使わない端末を解除してください。`,
      not_found: "対象が見つかりません。",
      recent_login_required:
        "パスワードの確認ができませんでした。いったんログアウトして、ログインし直してから、もう一度お試しください。",
    };
    throw new Error(
      messages[data.error] ?? `APIの呼び出しに失敗しました (${response.status})`,
    );
  }

  return data;
}

let minExchangePoints = null;

function showBalance(balance) {
  els.points.textContent = yen.format(balance.points);
  els.tokens.textContent = yen.format(balance.tokens);

  // 交換のルールは、サーバーが決めた値を表示する
  const rule = balance.exchange;
  if (rule) {
    minExchangePoints = rule.minPoints;
    els.exchangeRule.textContent =
      `${yen.format(rule.minPoints)}ポイント以上から交換できます` +
      `(1ポイント = ${rule.tokensPerPoint}トークン)`;
    if (!els.exchangePoints.value) els.exchangePoints.value = rule.minPoints;

    // 交換できるポイントに届いていないときは、あといくつかを表示する(表示だけ。交換の処理は変わらない)
    const shortage = rule.minPoints - balance.points;
    els.exchangeHint.hidden = shortage <= 0;
    els.exchangeHint.textContent = `あと ${yen.format(shortage)} ポイントで交換できます`;
  }
}

async function loadBalance() {
  if (!apiBase) {
    show("config.js に、apiBase(APIのURL)を入れてください。");
    return;
  }
  showBalance(await callApi("GET", "/me"));
}

// ---------- ポイントの履歴

// 続きを読み込むための目印(サーバーが返した next)。続きがなければ null
let historyNext = null;
let historyLoading = false;

// 日時は、日本時間で表示する
const historyTime = new Intl.DateTimeFormat("ja-JP", {
  timeZone: "Asia/Tokyo",
  year: "numeric",
  month: "numeric",
  day: "numeric",
  hour: "2-digit",
  minute: "2-digit",
});

function signed(value) {
  return `${value > 0 ? "+" : ""}${yen.format(value)}`;
}

function historyRow(entry) {
  const item = document.createElement("li");

  // 内容(ゲームの名前などはサーバーが決めた文字だが、念のため textContent で表示する)
  const left = document.createElement("div");
  const label = document.createElement("div");
  label.className = "rowTitle";
  label.textContent = entry.label;
  const time = document.createElement("div");
  time.className = "historyTime";
  time.textContent = historyTime.format(new Date(entry.createdAt * 1000));
  left.append(label, time);

  // ポイントの増減(トークンが増えたときは、その数も出す)。数字を大きく、単位を小さくする
  const right = document.createElement("div");
  right.className = "historyAmount";
  right.append(amountLine(signed(entry.points), "ポイント", entry.points >= 0 ? "plus" : "minus"));

  if (entry.tokens !== 0) {
    right.append(amountLine(signed(entry.tokens), "トークン", ""));
  }

  item.append(left, right);
  return item;
}

function amountLine(number, unit, className) {
  const line = document.createElement("div");
  if (className) line.className = className;
  const small = document.createElement("small");
  small.textContent = ` ${unit}`;
  line.append(number, small);
  return line;
}

// reset: true なら、先頭から読み直す(交換した直後など)。false なら、続きを足す
async function loadHistory({ reset }) {
  if (historyLoading) return;
  historyLoading = true;
  els.historyMore.disabled = true;

  try {
    const next = reset ? null : historyNext;
    const path = next ? `/history?next=${encodeURIComponent(next)}` : "/history";
    const data = await callApi("GET", path);

    if (reset) els.historyList.replaceChildren();
    els.historyList.append(...data.entries.map(historyRow));

    historyNext = data.next ?? null;
    els.historyEmpty.hidden = els.historyList.children.length > 0;
    els.historyMore.hidden = historyNext === null;
  } finally {
    historyLoading = false;
    els.historyMore.disabled = false;
  }
}

// 履歴の読み込みに失敗しても、残高などの表示は止めない
async function refreshHistory() {
  try {
    await loadHistory({ reset: true });
  } catch (e) {
    show(e.message);
  }
}

// ---------- アプリの紐づけ

// 紐づけの手続きを終えて、アプリが受け取りに来るのを待っているもの
// (端末は、アプリが受け取りに来たときに登録される。ブラウザを開いている間、アプリは止まっている)
let pendingPair = null;

// 紐づけのエラー(入力欄のすぐ下に出す)
function setPairError(text) {
  const el = document.getElementById("pairError");
  el.textContent = text || "";
  el.hidden = !text;
}

function setPairStatus(text) {
  document.getElementById("pairStatusText").textContent = text || "";
  document.getElementById("pairStatus").hidden = !text;
}

function showDevices({ devices }) {
  els.deviceCount.textContent = String(devices.length);

  // 待っていたアプリが、トークンを受け取って(受け取り前の印が消えて)、完了したら知らせる
  if (
    pendingPair &&
    devices.some(
      (d) =>
        d.appId === pendingPair.appId &&
        !d.pending &&
        d.createdAt * 1000 >= pendingPair.since - 60000
    )
  ) {
    setPairStatus(`「${pendingPair.appName}」の紐づけが完了しました。`);
    pendingPair = null;
  }

  els.deviceList.replaceChildren();

  for (const device of devices) {
    const item = document.createElement("li");

    // 端末の名前は、アプリ側から送られた文字なので、textContentで表示する
    const left = document.createElement("div");
    const name = document.createElement("div");
    name.className = "rowTitle";
    name.textContent = device.appName;
    const sub = document.createElement("div");
    sub.className = "rowSub";
    // 受け取り前(Webで確定したが、アプリがまだトークンを受け取っていない)の端末は、そう分かるようにする
    sub.textContent = device.pending
      ? `${device.label} ・ アプリに戻ると、紐づけが完了します`
      : `${device.label} ・ ${new Date(device.createdAt * 1000).toLocaleDateString("ja-JP")}に紐づけ`;
    left.append(name, sub);

    const button = document.createElement("button");
    button.className = "pill";
    button.textContent = "解除";
    button.onclick = () => unlinkDevice(device);

    item.append(left, button);
    els.deviceList.append(item);
  }
}

async function loadDevices() {
  showDevices(await callApi("GET", "/devices"));
}

// 一覧を、自動で最新にする(アプリ側で解除したときや、アプリが紐づけを終えたときのため)
const DEVICE_REFRESH_MS = 5000;

async function refreshDevicesQuietly() {
  if (document.hidden || !sessionStorage.getItem("access_token")) return;

  try {
    await loadDevices();
  } catch {
    // 通信の失敗は、次の更新で取り戻すため、表示しない
  }
}

// 紐づけの直後は、アプリが受け取りに来て完了するまで、短い間隔で確かめる
async function waitForDeviceChange() {
  for (let i = 0; i < 20 && pendingPair; i++) {
    await new Promise((resolve) => setTimeout(resolve, 1500));
    await refreshDevicesQuietly();
  }
}

setInterval(refreshDevicesQuietly, DEVICE_REFRESH_MS);
document.addEventListener("visibilitychange", refreshDevicesQuietly);

// ページに合わせた確認のダイアログ(OKなら true、キャンセルなら false)
// ブラウザ標準の confirm() は、ドメイン名が出て見た目も変えられないため使わない
function confirmDialog({ title, detail, note, okText }) {
  const dialog = document.getElementById("confirmDialog");

  // 古いブラウザなど、dialog が使えないときは、標準の確認で代わりにする
  if (typeof dialog.showModal !== "function") {
    return Promise.resolve(confirm([title, detail, note].filter(Boolean).join("\n")));
  }

  const set = (id, text) => {
    const el = document.getElementById(id);
    el.textContent = text || "";
    return el;
  };

  set("confirmTitle", title);
  document.getElementById("confirmDetail").hidden = !detail;
  set("confirmDetail", detail);
  document.getElementById("confirmNote").hidden = !note;
  set("confirmNoteText", note);
  set("confirmOk", okText);

  return new Promise((resolve) => {
    const ok = document.getElementById("confirmOk");
    const cancel = document.getElementById("confirmCancel");

    const finish = (result) => {
      ok.onclick = cancel.onclick = null;
      dialog.onclose = null;
      if (dialog.open) dialog.close();
      resolve(result);
    };

    ok.onclick = () => finish(true);
    cancel.onclick = () => finish(false);
    // Esc キーなどで閉じたときは、キャンセル
    dialog.onclose = () => finish(false);

    dialog.showModal();
    // 最初のボタンに枠が付かないよう、見出しにフォーカスを置く
    document.getElementById("confirmTitle").focus();
  });
}

async function pairDevice() {
  const code = els.pairingCode.value.trim();

  // 前の紐づけの案内・エラーは、消す
  setPairStatus("");
  setPairError("");

  if (!/^\d{6}$/.test(code)) {
    setPairError("6桁の数字を入力してください。");
    return;
  }

  try {
    // どの端末のコードかを先に確認して、本人に確かめてもらう
    const { label, appName, appId } = await callApi("POST", "/pairing/lookup", { code });

    const ok = await confirmDialog({
      title: `「${appName}」を紐づけますか？`,
      detail: `端末: ${label}`,
      note: "ご自身のアプリに表示されたコードのときだけ、紐づけてください。",
      okText: "紐づける",
    });
    if (!ok) return;

    await callApi("POST", "/pairing/confirm", { code });
    els.pairingCode.value = "";
    els.message.textContent = "";
    pendingPair = { appId, appName, since: Date.now() };
    // 端末は、確定した時点で、一覧に出る(アプリが受け取るまでは「受け取り前」と表示される)
    await loadDevices();
    els.deviceList.scrollIntoView({ block: "nearest", behavior: "smooth" });
    // アプリがトークンを受け取りに来て、紐づけが完了するまで、一覧を確かめる
    waitForDeviceChange();
  } catch (e) {
    // 入力欄のすぐ下に出す(ページの一番下に出すと、見えない)
    setPairError(e.message);
  }
}

async function unlinkDevice(device) {
  const name = `${device.appName}(${device.label})`;
  const ok = await confirmDialog({
    title: `「${name}」の紐づけを解除しますか？`,
    detail: "解除すると、この端末では、ポイントが貯まらなくなります。貯めたポイントは、そのまま残ります。",
    okText: "解除する",
  });
  if (!ok) return;

  try {
    await callApi("DELETE", `/devices/${encodeURIComponent(device.deviceId)}`);
    await loadDevices();
    showNotice(`「${name}」の紐づけを解除しました。`);
  } catch (e) {
    show(e.message);
  }
}

async function grantForTest() {
  try {
    showBalance(await callApi("POST", "/dev/grant", { amount: 10000 }));
    showNotice("テスト用に、10,000ポイントを追加しました。");
    await refreshHistory();
  } catch (e) {
    show(e.message);
  }
}

// ボタンを押した1回の操作ごとに、IDを作る。
// 通信が失敗して、同じ操作を送り直しても、サーバーは1回しか実行しない。
let pendingExchange = null;

async function exchange() {
  const points = Number(els.exchangePoints.value);

  if (!Number.isInteger(points) || points <= 0) {
    show("ポイントは、1以上の整数で入力してください。");
    return;
  }
  if (minExchangePoints !== null && points < minExchangePoints) {
    show(`${yen.format(minExchangePoints)}ポイント以上から交換できます。`);
    return;
  }

  // 同じポイント数の操作の送り直しなら、同じIDを使う
  if (!pendingExchange || pendingExchange.points !== points) {
    pendingExchange = { points, requestId: crypto.randomUUID() };
  }

  const button = document.getElementById("exchangeButton");
  button.disabled = true;

  try {
    showBalance(await callApi("POST", "/exchange", pendingExchange));
    pendingExchange = null;
    showNotice(`${yen.format(points)}ポイントを、トークンに交換しました。`);
    await refreshHistory();
  } catch (e) {
    show(e.message);
  } finally {
    button.disabled = false;
  }
}

// ---------- アカウントの削除
//
// 流れ: 説明とメールアドレスの確認 → パスワードを入れてログインし直す → 最後の確認 → 削除
// (ログインし直した時刻は、サーバーが確かめる。直近5分以内でないと、削除されない)

function showDeleteStep(step) {
  els.deleteIntro.hidden = step !== "intro";
  els.deleteForm.hidden = step !== "form";
  els.deleteConfirm.hidden = step !== "confirm";
}

function startDelete() {
  els.deleteEmail.value = "";
  showDeleteStep("form");
  els.deleteEmail.focus();
}

function cancelDelete() {
  sessionStorage.removeItem("pending_delete");
  showDeleteStep("intro");
}

async function continueDelete() {
  const email = readJwt(sessionStorage.getItem("id_token")).email ?? "";
  const typed = els.deleteEmail.value.trim().toLowerCase();

  if (!email || typed !== email.toLowerCase()) {
    show("メールアドレスが、ログイン中のものと一致しません。");
    return;
  }

  // ログインし直して戻ってきたときに、続きの確認画面を出すための目印
  sessionStorage.setItem("pending_delete", "1");
  await login({ forceLogin: true });
}

async function executeDelete() {
  const button = document.getElementById("deleteExecuteButton");
  button.disabled = true;

  try {
    await callApi("DELETE", "/me");
    sessionStorage.clear();
    render();
    showNotice("アカウントを削除しました。ご利用ありがとうございました。");
  } catch (e) {
    show(e.message);
    // 5分を過ぎたなどで、削除できなかったときは、最初からやり直してもらう
    sessionStorage.removeItem("pending_delete");
    showDeleteStep("intro");
  } finally {
    button.disabled = false;
  }
}

// ---------- 画面

function render() {
  const idToken = sessionStorage.getItem("id_token");

  if (!idToken) {
    els.signedOut.hidden = false;
    els.signedIn.hidden = true;
    return;
  }

  els.email.textContent = readJwt(idToken).email ?? "(メールアドレス不明)";
  els.signedOut.hidden = true;
  els.signedIn.hidden = false;
}

// 自動で入れるのは入力欄まで。紐づけるかどうかは、本人が内容を見て決める
function fillPendingPairingCode() {
  const pending = sessionStorage.getItem("pending_pair");
  if (!pending) return;

  sessionStorage.removeItem("pending_pair");
  els.pairingCode.value = pending;
  els.pairingCode.scrollIntoView({ block: "center" });
  showNotice("アプリのコードを入力しました。内容を確かめて、「紐づける」を押してください。");
}

async function main() {
  if (!cognitoDomain || !clientId) {
    show("config.js に、Cognito のドメインとクライアントIDを入れてください。");
    return;
  }

  document.getElementById("loginButton").onclick = () => login();
  document.getElementById("logoutButton").onclick = logout;
  document.getElementById("grantButton").onclick = grantForTest;
  document.getElementById("exchangeButton").onclick = exchange;
  document.getElementById("pairingButton").onclick = pairDevice;
  document.getElementById("deleteStartButton").onclick = startDelete;
  document.getElementById("deleteContinueButton").onclick = () =>
    continueDelete().catch((e) => show(e.message));
  document.getElementById("deleteCancelButton").onclick = cancelDelete;
  document.getElementById("deleteCancelConfirmButton").onclick = cancelDelete;
  document.getElementById("deleteExecuteButton").onclick = executeDelete;
  els.historyMore.onclick = () =>
    loadHistory({ reset: false }).catch((e) => show(e.message));

  const query = new URLSearchParams(location.search);

  // アプリの「Webを開く」から来たときは、コードを入力欄に入れる(ログインを挟むため、保存しておく)
  const pair = query.get("pair");
  if (/^\d{6}$/.test(pair ?? "")) {
    sessionStorage.setItem("pending_pair", pair);
    history.replaceState(null, "", location.pathname);
  }

  try {
    if (query.get("error")) {
      throw new Error(`ログインできませんでした: ${query.get("error")}`);
    }
    if (query.get("code")) {
      await handleCallback(query.get("code"), query.get("state"));
    }
  } catch (e) {
    show(e.message);
  }

  render();

  // 削除の途中で、パスワードを入れてログインし直して戻ってきたときだけ、最後の確認を出す
  // (ログインし直さずに開き直したときは、途中の状態を捨てる)
  if (sessionStorage.getItem("pending_delete")) {
    if (query.get("code") && sessionStorage.getItem("access_token")) {
      showDeleteStep("confirm");
      els.deleteConfirm.scrollIntoView({ block: "center" });
    } else {
      sessionStorage.removeItem("pending_delete");
    }
  }

  if (sessionStorage.getItem("access_token")) {
    try {
      await loadBalance();
      await loadHistory({ reset: true });
      await loadDevices();
      fillPendingPairingCode();
    } catch (e) {
      show(e.message);
      render();
    }
  }
}

main();
