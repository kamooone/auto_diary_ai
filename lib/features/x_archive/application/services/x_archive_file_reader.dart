import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../domain/entities/x_archive_post.dart';
import '../../domain/services/x_archive_parser.dart';

/// 選んだ tweets.js を読んで、投稿の一覧にする
///
/// 数十MBのファイルを読むので、画面が固まらないよう別のIsolateで処理する。
Future<List<XArchivePost>> readXArchiveFile(String path) {
  return compute(_readAndParse, path);
}

List<XArchivePost> _readAndParse(String path) {
  final source = utf8.decode(File(path).readAsBytesSync());
  return const XArchiveParser().parse(source);
}
