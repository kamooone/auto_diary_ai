import 'dart:io';

/// AdMobの広告ユニットID
///
/// いまはGoogleが公開しているテスト用のIDで、本物の広告は表示されない。
/// 本番のIDを作成したら、ここの値を差し替える
/// (アプリIDは、AndroidManifest.xmlとIos/Runner/Info.plistにも入っている)
class AdUnitIds {
  AdUnitIds._();

  static String get banner => Platform.isIOS
      ? 'ca-app-pub-3940256099942544/2934735716'
      : 'ca-app-pub-3940256099942544/6300978111';

  static String get interstitial => Platform.isIOS
      ? 'ca-app-pub-3940256099942544/4411468910'
      : 'ca-app-pub-3940256099942544/1033173712';

  static String get rewarded => Platform.isIOS
      ? 'ca-app-pub-3940256099942544/1712485313'
      : 'ca-app-pub-3940256099942544/5224354917';
}
