// ゲームの紹介の一覧(ゲームを足すときは、ここに1つ足すだけ)
//
//   id       : ゲームのID(サーバーのアプリ一覧 APPS と同じ名前にする)
//   name     : ゲームの名前
//   summary  : 紹介の文(1〜2文)
//   points   : ポイントの貯まり方の説明
//   icon     : アイコンの画像(同じフォルダに置いたファイル名)。なければ、頭文字を表示する
//   storeUrl : Google Play のページのアドレス。まだ公開していないときは、空にする(ボタンを出さない)
window.GAMES = [
  {
    id: "kamoooneshot",
    name: "KamoooneShot",
    summary: "(紹介の文を、ここに入れます)",
    points: "ステージをクリアすると、50ポイントが貯まります。",
    icon: "",
    storeUrl: "",
  },
];
