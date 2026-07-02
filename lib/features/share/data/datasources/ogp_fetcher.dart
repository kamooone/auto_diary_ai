import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

class OgpFetcher {
  Future<String?> fetchText(String url) async {
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) return null;

    final doc = parser.parse(res.body);
    final meta = doc.querySelector('meta[property="og:description"]');

    return meta?.attributes['content'];
  }
}