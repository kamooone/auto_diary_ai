import 'dart:io';

/// AdMobの広告ユニットID(本番)
///
/// IDを返さない(null)場合は、その広告を出さない。
/// - iOS: まだ広告ユニットを作っていないため、広告を出さない(iOSで出すときに、ここに足す)
/// - リワード: まだ広告ユニットを作っていないため、広告を出さない(作ったら、ここに足す)
///
/// アプリIDは、AndroidManifest.xml(Android)と ios/Runner/Info.plist(iOS)にも入っている。
/// 開発の端末は、AdMobの管理画面で「テスト端末」に登録してあるため、本番のIDでも、
/// 自分の端末にはテスト広告が出る(自分の広告を押してしまう心配はない)。
class AdUnitIds {
  AdUnitIds._();

  /// バナー広告(diary_banner)
  static String? get banner =>
      Platform.isAndroid ? 'ca-app-pub-2678597473306441/4955576993' : null;

  /// インタースティシャル広告(diary_map_interstitial)。地図を開く直前に出す
  static String? get interstitial =>
      Platform.isAndroid ? 'ca-app-pub-2678597473306441/4813388025' : null;

  /// リワード広告。AIに日記を書いてもらう前に出す(広告ユニットを作ったら、IDを入れる)
  static String? get rewarded => null;
}
