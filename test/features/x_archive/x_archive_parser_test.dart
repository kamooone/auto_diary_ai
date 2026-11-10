import 'dart:convert';

import 'package:auto_diary_ai/features/x_archive/domain/entities/x_archive_post.dart';
import 'package:auto_diary_ai/features/x_archive/domain/services/x_archive_parser.dart';
import 'package:flutter_test/flutter_test.dart';

/// 実際のアーカイブと同じ形の、作り物のデータ
String _js(List<Map<String, dynamic>> tweets) {
  final list = tweets.map((t) => {'tweet': t}).toList();
  return 'window.YTD.tweets.part0 = ${const JsonEncoder.withIndent('  ').convert(list)}';
}

Map<String, dynamic> _tweet({
  String id = '100',
  String text = 'こんにちは',
  String createdAt = 'Fri Nov 06 12:40:45 +0000 2026',
  Map<String, dynamic> extra = const {},
}) {
  return {
    'id_str': id,
    'full_text': text,
    'created_at': createdAt,
    'entities': {'urls': []},
    ...extra,
  };
}

void main() {
  const parser = XArchiveParser();

  test('通常の投稿を読む(日時はUTC)', () {
    final posts = parser.parse(_js([_tweet()]));
    expect(posts, hasLength(1));
    expect(posts.single.tweetId, '100');
    expect(posts.single.text, 'こんにちは');
    expect(posts.single.kind, XArchivePostKind.post);
    expect(posts.single.createdAt, DateTime.utc(2026, 11, 6, 12, 40, 45));
    expect(posts.single.url, 'https://x.com/i/status/100');
  });

  test('HTMLの記号を戻す', () {
    final posts = parser.parse(_js([_tweet(text: 'A &amp; B &lt;3 &gt; C')]));
    expect(posts.single.text, 'A & B <3 > C');
  });

  test('リプライは種類とリプライ先を持つ', () {
    final posts = parser.parse(_js([
      _tweet(extra: {
        'in_reply_to_status_id_str': '55',
        'in_reply_to_screen_name': 'someone',
      }),
    ]));
    expect(posts.single.kind, XArchivePostKind.reply);
    expect(posts.single.replyToScreenName, 'someone');
  });

  test('RTで始まる投稿はリツイート', () {
    final posts = parser.parse(_js([_tweet(text: 'RT @abc: 元の投稿…')]));
    expect(posts.single.kind, XArchivePostKind.retweet);
  });

  test('他の投稿へのリンクを含むと引用リツイート', () {
    final posts = parser.parse(_js([
      _tweet(text: '見て https://t.co/xyz', extra: {
        'entities': {
          'urls': [
            {'expanded_url': 'https://x.com/other/status/999'},
          ],
        },
      }),
    ]));
    expect(posts.single.kind, XArchivePostKind.quote);
  });

  test('ふつうのリンクだけでは引用にならない', () {
    final posts = parser.parse(_js([
      _tweet(extra: {
        'entities': {
          'urls': [
            {'expanded_url': 'https://example.com/page'},
          ],
        },
      }),
    ]));
    expect(posts.single.kind, XArchivePostKind.post);
  });

  test('画像のファイル名は「投稿ID-元の名前」で、本文のURLは消える', () {
    final posts = parser.parse(_js([
      _tweet(id: '200', text: '写真 https://t.co/img', extra: {
        'extended_entities': {
          'media': [
            {
              'type': 'photo',
              'url': 'https://t.co/img',
              'media_url_https': 'https://pbs.twimg.com/media/AAA.png',
            },
            {
              'type': 'photo',
              'url': 'https://t.co/img',
              'media_url_https': 'https://pbs.twimg.com/media/BBB.jpg',
            },
          ],
        },
      }),
    ]));
    expect(posts.single.text, '写真');
    expect(posts.single.imageFileNames, ['200-AAA.png', '200-BBB.jpg']);
    expect(posts.single.hasVideo, isFalse);
  });

  test('動画は画像に含めず、あることだけ覚える', () {
    final posts = parser.parse(_js([
      _tweet(id: '300', extra: {
        'extended_entities': {
          'media': [
            {
              'type': 'video',
              'url': 'https://t.co/v',
              'media_url_https': 'https://pbs.twimg.com/media/V.jpg',
            },
          ],
        },
      }),
    ]));
    expect(posts.single.imageFileNames, isEmpty);
    expect(posts.single.hasVideo, isTrue);
  });

  test('壊れた1件は飛ばし、ほかは読む', () {
    final list = [
      {'tweet': {'id_str': '1'}},
      {'tweet': _tweet(id: '2')},
    ];
    final posts = parser.parse('window.YTD.tweets.part0 = ${jsonEncode(list)}');
    expect(posts.map((p) => p.tweetId), ['2']);
  });

  test('配列が無いファイルは FormatException', () {
    expect(() => parser.parse('hello'), throwsFormatException);
  });

  test('画像の縦横比(横÷縦)を、sizesのlargeから求める', () {
    final posts = parser.parse(_js([
      _tweet(id: '400', extra: {
        'extended_entities': {
          'media': [
            {
              'type': 'photo',
              'url': 'https://t.co/a',
              'media_url_https': 'https://pbs.twimg.com/media/A.jpg',
              'sizes': {
                'large': {'w': '2000', 'h': '1000', 'resize': 'fit'},
              },
            },
            {
              'type': 'photo',
              'url': 'https://t.co/b',
              'media_url_https': 'https://pbs.twimg.com/media/B.jpg',
            },
          ],
        },
      }),
    ]));
    expect(posts.single.imageAspectRatios, [2.0, 0.0]);
  });
}
