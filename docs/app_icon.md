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
