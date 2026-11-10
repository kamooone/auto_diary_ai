import 'dart:convert';

import '../entities/x_archive_post.dart';

/// アーカイブの tweets.js を、投稿の一覧に直す
///
/// tweets.js は `window.YTD.tweets.part0 = [ {"tweet": {...}}, ... ]` の形。
/// 中身は先頭の `[` から後ろがJSONの配列になっている。
class XArchiveParser {
  const XArchiveParser();

  static final _statusUrl = RegExp(
    r'^https?://(?:www\.)?(?:x|twitter)\.com/[^/]+/status/\d+',
  );

  /// tweets.js の中身を読む。形が違うときは FormatException
  List<XArchivePost> parse(String source) {
    final start = source.indexOf('[');
    if (start < 0) {
      throw const FormatException('tweets.js の形ではありません');
    }
    final decoded = jsonDecode(source.substring(start));
    if (decoded is! List) {
      throw const FormatException('tweets.js の形ではありません');
    }

    final posts = <XArchivePost>[];
    for (final item in decoded) {
      if (item is! Map) continue;
      final tweet = item['tweet'];
      if (tweet is! Map) continue;
      final post = _parseTweet(tweet);
      if (post != null) posts.add(post);
    }
    return posts;
  }

  XArchivePost? _parseTweet(Map tweet) {
    final id = tweet['id_str'];
    final createdAtText = tweet['created_at'];
    final fullText = tweet['full_text'];
    if (id is! String || createdAtText is! String || fullText is! String) {
      return null;
    }
    final createdAt = _parseCreatedAt(createdAtText);
    if (createdAt == null) return null;

    final media = _mediaList(tweet);
    final images = <String>[];
    final ratios = <double>[];
    var hasVideo = false;
    var text = fullText;
    for (final m in media) {
      final type = m['type'];
      // 本文の末尾に付く、画像や動画のURLは消す
      final shortUrl = m['url'];
      if (shortUrl is String && shortUrl.isNotEmpty) {
        text = text.replaceAll(shortUrl, '');
      }
      if (type == 'photo') {
        final name = _imageFileName(id, m['media_url_https']);
        if (name != null) {
          images.add(name);
          ratios.add(_aspectRatio(m['sizes']));
        }
      } else {
        hasVideo = true;
      }
    }
    text = _unescapeHtml(text).trim();

    final replyTo = tweet['in_reply_to_status_id_str'];
    final screenName = tweet['in_reply_to_screen_name'];

    final XArchivePostKind kind;
    if (fullText.startsWith('RT @')) {
      kind = XArchivePostKind.retweet;
    } else if (replyTo is String && replyTo.isNotEmpty) {
      kind = XArchivePostKind.reply;
    } else if (_hasQuotedStatusUrl(tweet)) {
      kind = XArchivePostKind.quote;
    } else {
      kind = XArchivePostKind.post;
    }

    return XArchivePost(
      tweetId: id,
      text: text,
      createdAt: createdAt,
      kind: kind,
      replyToScreenName: kind == XArchivePostKind.reply &&
              screenName is String &&
              screenName.isNotEmpty
          ? screenName
          : null,
      imageFileNames: images,
      imageAspectRatios: ratios,
      hasVideo: hasVideo,
    );
  }

  /// sizes の large(なければ他)から、横÷縦を求める。分からなければ0
  double _aspectRatio(Object? sizes) {
    if (sizes is! Map) return 0;
    for (final key in ['large', 'medium', 'small']) {
      final size = sizes[key];
      if (size is! Map) continue;
      final w = num.tryParse('${size['w']}');
      final h = num.tryParse('${size['h']}');
      if (w != null && h != null && w > 0 && h > 0) return w / h;
    }
    return 0;
  }

  List<Map> _mediaList(Map tweet) {
    final extended = tweet['extended_entities'];
    if (extended is Map && extended['media'] is List) {
      return (extended['media'] as List).whereType<Map>().toList();
    }
    return const [];
  }

  /// 他の投稿へのリンクを含むか(引用リツイートの目印)
  bool _hasQuotedStatusUrl(Map tweet) {
    final entities = tweet['entities'];
    if (entities is! Map || entities['urls'] is! List) return false;
    for (final u in (entities['urls'] as List).whereType<Map>()) {
      final expanded = u['expanded_url'];
      if (expanded is String && _statusUrl.hasMatch(expanded)) return true;
    }
    return false;
  }

  /// アーカイブの tweets_media の中の名前は「投稿ID-元のファイル名」
  String? _imageFileName(String tweetId, Object? mediaUrl) {
    if (mediaUrl is! String) return null;
    final base = mediaUrl.split('/').last;
    if (base.isEmpty) return null;
    return '$tweetId-$base';
  }

  static const _months = {
    'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
    'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
  };

  /// `Fri Nov 06 12:40:45 +0000 2026` をUTCの日時にする
  DateTime? _parseCreatedAt(String text) {
    final m = RegExp(r'^\w{3} (\w{3}) (\d{1,2}) (\d{2}):(\d{2}):(\d{2}) \+0000 (\d{4})$')
        .firstMatch(text);
    if (m == null) return null;
    final month = _months[m.group(1)];
    if (month == null) return null;
    return DateTime.utc(
      int.parse(m.group(6)!),
      month,
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
      int.parse(m.group(4)!),
      int.parse(m.group(5)!),
    );
  }

  String _unescapeHtml(String text) {
    return text
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&amp;', '&');
  }
}
