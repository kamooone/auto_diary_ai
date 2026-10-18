// Cognito の設定(秘密の値ではない。ブラウザに公開されても問題ない)
// AWSコンソールで確認した値を、"" の中に入れる
window.APP_CONFIG = {
  cognitoDomain:
    "https://ap-northeast-1lzwjvwme5.auth.ap-northeast-1.amazoncognito.com",
  clientId: "40mo7eomg4ibl26amd4d1npj9f",
  // ポイントのAPIのURL(手順3-3で作る。末尾に / は付けない)
  // 例: "https://xxxx.execute-api.ap-northeast-1.amazonaws.com"
  apiBase: "",
};
