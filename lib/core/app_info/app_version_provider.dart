import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// アプリのバージョンとビルド番号(「1.0.0 (2)」の形式)
///
/// pubspec.yamlの`version: 1.0.0+2`に対応する
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();

  var buildNumber = int.tryParse(info.buildNumber) ?? 0;

  // AndroidでCPUの種類ごとに分けたAPKは、ビルド番号に「種類の番号×1000」が足されている
  // (例: arm64は2000 + ビルド番号)ため、pubspec.yamlの番号に戻す
  if (Platform.isAndroid) {
    buildNumber %= 1000;
  }

  return "${info.version} ($buildNumber)";
});
