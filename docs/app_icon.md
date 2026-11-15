# アプリアイコン

デザインは Claude Design で作った(顔のピン + 点線の道 + ノートのピン、薄いピンクの背景)。元の画像(SVG)は `assets/icon/` にある。

| ファイル | 内容 |
|---|---|
| `assets/icon/icon_background.svg` | 背景(薄いピンクと、地図の線) |
| `assets/icon/icon_foreground.svg` | 前景(顔のピン、点線、ノートのピン)。安全な範囲(中央60%)に収めてある |
| `assets/icon/icon_full.svg` | 背景と前景を重ねたもの |
| `assets/icon/icon_monochrome.svg` | Android 13のテーマアイコン用(単色) |
| `assets/icon/png/*.png` | 上のSVGから作ったPNG(`flutter_launcher_icons` の入力) |
| `assets/icon/png/play_store_512.png` | Google Playのストア掲載用(512×512) |

## 作り直す手順

1. SVGをPNGにする(macOS)。`qlmanage` は透明を白で塗るので、前景とモノクロは、あとで透明にする。
   ```
   qlmanage -t -s 1024 -o <出力フォルダ> assets/icon/icon_*.svg
   ```
2. 前景: 外側の白を透明にする。
   ```
   magick foreground.png -alpha set -fuzz 1% -fill none \
     -draw "color 0,0 floodfill" -draw "color 1023,0 floodfill" \
     -draw "color 0,1023 floodfill" -draw "color 1023,1023 floodfill" foreground.png
   ```
   モノクロ: 黒を不透明、白を透明にする。
   ```
   magick monochrome.png -colorspace Gray -negate -alpha copy -channel RGB -evaluate set 0 +channel monochrome.png
   ```
3. 各サイズの画像を作る。`pubspec.yaml` の `flutter_launcher_icons` の設定を使う。
   ```
   dart pub global activate flutter_launcher_icons
   dart pub global run flutter_launcher_icons
   ```
   - プロジェクトの依存には入れない(`archive` のバージョンが合わず、ビルドできないため)。
   - `adaptive_icon_foreground_inset: 0` にしている。ツールの初めの値(16%)だと、安全な範囲に収めた前景が、さらに縮む。
   - ツールが `ios/Runner.xcodeproj/project.pbxproj` を、おかしな値に書き換える(`ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = AppIcon`)。実行後に `git checkout ios/Runner.xcodeproj/project.pbxproj` で戻す。

## 通知の小さいアイコン(Android)

- Androidの通知の小さいアイコンは、色を使えず、不透明な部分の形だけが、白く表示される。アプリのアイコン(カラー)は、そのままでは使えない。
- 専用の単色アイコン `assets/icon/notification_icon.svg`(ピンに、スマイルの穴)から、`android/app/src/main/res/drawable-*/ic_notification.png`(24〜96px)を作った。
  - 作り方: `qlmanage -t -s 512` でPNGにして、黒=不透明、白=透明にする(アイコンのPNGと同じ)。そのあと、絵の余白を切り詰めて(`-trim`)、高さ約92%に広げてから、各サイズに縮小する。
  - **SVGの `width` と `height` は、512にしておく。** 小さい値(96など)だと、`qlmanage` が、その大きさのまま、512の画像の中に置くので、絵が、画像の3割ほどに縮んでしまう(最初に作ったとき、これで、通知の中で、点のようにしか見えなかった)。
  - Android 12以降は、通知の小さいアイコンを、色つきの丸の中に、小さく表示する。細かい絵(顔の線、小さいピン、点線)は、つぶれる。太い1つの形にする。モノクロのアイコン(`icon_monochrome.svg`)は、細かすぎて、使えなかった。
- 使っている場所: ローカルの通知(`notification_permission_service.dart`、`x_archive_recall_notifier.dart`)と、お問い合わせの返信のプッシュ通知(`AndroidManifest.xml` の `default_notification_icon`)。
- 通知を広げたときの色は、アプリの紺(`#3F5879`、`res/values/colors.xml` の `notification_accent`)。
- iOSの通知は、アプリのアイコン(カラー)が、自動で使われる。
