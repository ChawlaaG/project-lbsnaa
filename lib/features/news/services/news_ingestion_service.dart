import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// import '../../ai_sensei/services/gemini_content_service.dart'; // Disabled: AI summaries removed
class NewsIngestionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // RSS Feed URL - Using The Hindu National as primary source
  // Alternative: 'https://timesofindia.indiatimes.com/rssfeedstopstories.cms'
  static const String _rssUrl =
      'https://www.thehindu.com/news/national/feeder/default.rss';

  Future<void> fetchAndIngestRSS() async {
    try {
      debugPrint('📡 CONTACTING NEWSWIRE: $_rssUrl');
      final response = await http.get(Uri.parse(_rssUrl));

      if (response.statusCode == 200) {
        // Decode bytes directly as UTF-8, allowing malformed characters.
        // This solves the mojibake issue that happens when http falls back to Latin-1
        // because the RSS feed is missing charset declaration in content-type.
        final decodedBody = utf8.decode(
          response.bodyBytes,
          allowMalformed: true,
        );
        final document = XmlDocument.parse(decodedBody);
        final items = document.findAllElements('item');

        debugPrint('📄 PARSED ${items.length} ARTICLES.');

        int newArticles = 0;

        for (var item in items) {
          final title = item.findElements('title').first.innerText;
          final link = item.findElements('link').first.innerText;
          final description = item.findElements('description').first.innerText;
          final pubDateStr = item.findElements('pubDate').first.innerText;

          // Check for duplication first to save AI tokens
          final isDuplicate = await _checkDuplicate(link);

          if (!isDuplicate) {
            // Clean description (remove HTML tags if any and unescape entities)
            final unescape = HtmlUnescape();
            final safeTitle = unescape.convert(title);
            final cleanDescBase = _cleanHtml(description);
            final safeDesc = unescape.convert(cleanDescBase);

            // Phase 6: Global Intel - Native RSS Parsing (Bypassing AI to save quota & prevent hangs)
            // We use the cleaned description as input
            // Provide a sensible fallback if description is empty
            String summary = safeDesc;
            if (safeDesc.length > 150) {
              // roughly cut to the first sentence or 150 chars
              int firstPeriod = safeDesc.indexOf('.');
              if (firstPeriod != -1 && firstPeriod < 150) {
                summary = safeDesc.substring(0, firstPeriod + 1);
              } else {
                summary = "${safeDesc.substring(0, 147)}...";
              }
            }

            final fullArticleFromRSS = safeDesc;
            final tags = ['National', 'News'];

            await _firestore.collection('daily_brief').add({
              'headline': safeTitle,
              'summary': "• $summary", // Native summary
              'fullArticle': fullArticleFromRSS, // Native expanded
              'sourceUrl': link,
              'timestamp': FieldValue.serverTimestamp(),
              'originalPubDate': pubDateStr,
              'tags': tags,
              'isRead': false,
              'aiProcessed': false, // No longer AI processed
            });
            newArticles++;
          }
        }
        debugPrint('✅ INGESTION COMPLETE. NEW INTEL: $newArticles');
      } else {
        debugPrint('❌ CONNECTION FAILED: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ INGESTION ERROR: $e');
    }
  }

  Future<bool> _checkDuplicate(String url) async {
    final query = await _firestore
        .collection('daily_brief')
        .where('sourceUrl', isEqualTo: url)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  String _cleanHtml(String htmlString) {
    // Simple regex to strip HTML tags
    final RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '').trim();
  }

  // Temporary function to clear corrupted database entries
  Future<void> clearNewsDatabase() async {
    // Safety: require explicit env flag to run destructive ops.
    if (dotenv.env['ALLOW_DB_WIPE'] != 'true') {
      debugPrint('🚨 DATABASE WIPE BLOCKED: ALLOW_DB_WIPE not set to true.');
      return;
    }

    debugPrint('🚨 INITIATING DATABASE WIPE...');
    try {
      final batch = _firestore.batch();
      var snapshots = await _firestore.collection('daily_brief').get();
      for (var doc in snapshots.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      debugPrint(
        '✅ DATABASE WIPE COMPLETE. ${snapshots.docs.length} corrupted records destroyed.',
      );
    } catch (e) {
      debugPrint('❌ FAILED TO WIPE DATABASE: $e');
    }
  }
}
