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
  pairingCode: document.getElementById("pairingCode"),
  deviceCount: document.getElementById("deviceCount"),
  deviceList: document.getElementById("deviceList"),
  message: document.getElementById("message"),
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

async function login() {
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
  }
}

async function loadBalance() {
  if (!apiBase) {
    show("config.js に、apiBase(APIのURL)を入れてください。");
    return;
  }
  showBalance(await callApi("GET", "/me"));
}

// ---------- アプリの紐づけ

function showDevices({ devices }) {
  els.deviceCount.textContent = String(devices.length);
  els.deviceList.replaceChildren();

  for (const device of devices) {
    const item = document.createElement("li");
    // 端末の名前は、アプリ側から送られた文字なので、textContentで表示する
    item.append(
      `${device.appName}(${device.label}・${new Date(device.createdAt * 1000).toLocaleDateString("ja-JP")}に紐づけ) `,
    );

    const button = document.createElement("button");
    button.textContent = "解除";
    button.onclick = () => unlinkDevice(device);
    item.append(button);

    els.deviceList.append(item);
  }
}

async function loadDevices() {
  showDevices(await callApi("GET", "/devices"));
}

async function pairDevice() {
  const code = els.pairingCode.value.trim();

  if (!/^\d{6}$/.test(code)) {
    show("6桁の数字を入力してください。");
    return;
  }

  try {
    // どの端末のコードかを先に確認して、本人に確かめてもらう
    const { label, appName } = await callApi("POST", "/pairing/lookup", { code });

    if (!confirm(`「${appName}」(${label})を、このアカウントに紐づけますか？\n(ご自身のアプリに表示されたコードのときだけ、紐づけてください)`)) {
      return;
    }

    await callApi("POST", "/pairing/confirm", { code });
    els.pairingCode.value = "";
    await loadDevices();
    showNotice(`「${appName}」を紐づけました。アプリの画面に戻ってください。`);
  } catch (e) {
    show(e.message);
  }
}

async function unlinkDevice(device) {
  const name = `${device.appName}(${device.label})`;
  if (!confirm(`「${name}」の紐づけを解除しますか？`)) return;

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
  } catch (e) {
    show(e.message);
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

  document.getElementById("loginButton").onclick = login;
  document.getElementById("logoutButton").onclick = logout;
  document.getElementById("grantButton").onclick = grantForTest;
  document.getElementById("exchangeButton").onclick = exchange;
  document.getElementById("pairingButton").onclick = pairDevice;

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

  if (sessionStorage.getItem("access_token")) {
    try {
      await loadBalance();
      await loadDevices();
      fillPendingPairingCode();
    } catch (e) {
      show(e.message);
      render();
    }
  }
}

main();
