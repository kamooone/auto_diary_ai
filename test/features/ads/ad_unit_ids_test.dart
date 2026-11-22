import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  // Googleが公開している、テスト用の広告のID(本物の広告は出ない)に共通する部分
  const googleSamplePublisher = '3940256099942544';

  test('アプリのコードとAndroidの設定に、テスト用の広告IDが残っていない', () {
    final files = [
      ...Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart')),
      File('android/app/src/main/AndroidManifest.xml'),
    ];

    final found = [
      for (final file in files)
        if (file.readAsStringSync().contains(googleSamplePublisher)) file.path,
    ];

    expect(found, isEmpty, reason: '本番のIDに差し替える(テスト端末は、AdMobの管理画面で登録する)');
  });

  test('AndroidManifestのアプリIDは、本番のID(~が付く形)', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();

    expect(
      manifest,
      contains('ca-app-pub-2678597473306441~7581740331'),
    );
  });
}
