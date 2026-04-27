import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart';

class NewsService {
  static const String _trelazeFeedUrl = 'https://www.trelaze.fr/feed';
  static const String _cacheKeyAll = 'cache_news_all';
  static const String _cacheKeyTrelaze = 'cache_news_trelaze';

  static const List<Map<String, String>> _rssFeeds = [
    {
      'name': 'Ville de Trélazé',
      'url': _trelazeFeedUrl,
    },
    {
      'name': 'France 3 Angers',
      'url':
          'https://france3-regions.franceinfo.fr/pays-de-la-loire/maine-et-loire/angers/rss',
    },
    {
      'name': 'Angers.fr',
      'url': 'https://feeds.feedburner.com/ActualitesAngers',
    },
  ];

  static Future<List<Map<String, String>>> _loadCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List;
      return list.cast<Map<String, dynamic>>().map((e) =>
          e.map((k, v) => MapEntry(k, v.toString()))).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveCache(String key, List<Map<String, String>> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(data));
    } catch (_) {}
  }

  /// Toutes les sources (Trélazé + régionales)
  static Future<List<Map<String, String>>> getActualites() async {
    final articles = <Map<String, String>>[];
    bool anySuccess = false;
    for (final feed in _rssFeeds) {
      final result = await _fetchFeed(feed['url']!, feed['name']!);
      if (result.isNotEmpty) anySuccess = true;
      articles.addAll(result);
    }
    if (anySuccess) {
      await _saveCache(_cacheKeyAll, articles);
      return articles;
    }
    final cached = await _loadCache(_cacheKeyAll);
    return cached.isNotEmpty ? cached : articles;
  }

  /// Uniquement le flux officiel de Trélazé (pour la page d'accueil)
  static Future<List<Map<String, String>>> getActualitesTrelaze(
      {int limit = 5}) async {
    final all = await _fetchFeed(_trelazeFeedUrl, 'Ville de Trélazé');
    if (all.isNotEmpty) {
      await _saveCache(_cacheKeyTrelaze, all);
      return all.take(limit).toList();
    }
    final cached = await _loadCache(_cacheKeyTrelaze);
    return cached.take(limit).toList();
  }

  static Future<List<Map<String, String>>> _fetchFeed(
      String url, String sourceName) async {
    final articles = <Map<String, String>>[];
    try {
      final response = await http
          .get(Uri.parse(url), headers: {'User-Agent': 'MyTrelaze/1.0'})
          .timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) return articles;

      final document = XmlDocument.parse(response.body);
      final items = document.findAllElements('item');

      for (final item in items.take(10)) {
        final title =
            item.findElements('title').firstOrNull?.innerText ?? '';
        final description =
            item.findElements('description').firstOrNull?.innerText ?? '';
        final link =
            item.findElements('link').firstOrNull?.innerText ?? '';
        final pubDate =
            item.findElements('pubDate').firstOrNull?.innerText ?? '';
        final category =
            item.findElements('category').firstOrNull?.innerText ?? '';

        // ── Extraction image ─────────────────────────────────────────
        String imageUrl = '';

        // 1. media:content
        final mediaContent =
            item.findElements('media:content').firstOrNull;
        if (mediaContent != null) {
          imageUrl = mediaContent.getAttribute('url') ?? '';
        }

        // 2. enclosure
        if (imageUrl.isEmpty) {
          final enclosure =
              item.findElements('enclosure').firstOrNull;
          if (enclosure != null) {
            imageUrl = enclosure.getAttribute('url') ?? '';
          }
        }

        // 3. Premier <img src="..."> dans description
        if (imageUrl.isEmpty) {
          final imgMatch =
              RegExp(r'<img[^>]+src="([^"]+)"').firstMatch(description);
          if (imgMatch != null) {
            imageUrl = imgMatch.group(1) ?? '';
          }
        }

        // Préfère les variantes ~600-1024px du srcset trelaze.fr
        if (imageUrl.isNotEmpty &&
            imageUrl.contains('trelaze.fr') &&
            description.contains('srcset=')) {
          final srcsetMatch = RegExp(r'srcset="([^"]+)"')
              .firstMatch(description);
          if (srcsetMatch != null) {
            final srcset = srcsetMatch.group(1) ?? '';
            // Cherche ~1024w
            final best = RegExp(r'(https?://\S+) 1024w')
                .firstMatch(srcset);
            if (best != null) imageUrl = best.group(1)!;
          }
        }

        if (title.isNotEmpty) {
          articles.add({
            'title': title,
            'description': _stripHtml(description),
            'link': link,
            'date': pubDate,
            'source': sourceName,
            'image': imageUrl,
            'category': category,
          });
        }
      }
    } catch (_) {
      // Flux indisponible
    }
    return articles;
  }

  static String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
  }
}
