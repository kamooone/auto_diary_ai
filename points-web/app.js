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
}

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
  if (!response.ok) {
    throw new Error(`APIの呼び出しに失敗しました (${response.status})`);
  }

  return response.json();
}

function showBalance(balance) {
  els.points.textContent = balance.points;
  els.tokens.textContent = balance.tokens;
}

async function loadBalance() {
  if (!apiBase) {
    show("config.js に、apiBase(APIのURL)を入れてください。");
    return;
  }
  showBalance(await callApi("GET", "/me"));
}

async function grantForTest() {
  try {
    showBalance(await callApi("POST", "/dev/grant", { amount: 10 }));
  } catch (e) {
    show(e.message);
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

async function main() {
  if (!cognitoDomain || !clientId) {
    show("config.js に、Cognito のドメインとクライアントIDを入れてください。");
    return;
  }

  document.getElementById("loginButton").onclick = login;
  document.getElementById("logoutButton").onclick = logout;
  document.getElementById("grantButton").onclick = grantForTest;

  const query = new URLSearchParams(location.search);

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
    } catch (e) {
      show(e.message);
      render();
    }
  }
}

main();
