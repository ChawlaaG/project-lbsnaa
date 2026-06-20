import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

void main() async {
  final urls = [
    'https://www.thehindu.com/news/national/feeder/default.rss',
    'https://timesofindia.indiatimes.com/rssfeedstopstories.cms',
  ];
  
  for (var url in urls) {
    print('Testing: $url');
    try {
      final res = await http.get(Uri.parse(url));
      final doc = XmlDocument.parse(utf8.decode(res.bodyBytes, allowMalformed: true));
      final items = doc.findAllElements('item');
      if (items.isNotEmpty) {
        final first = items.first;
        final desc = first.findElements('description').firstOrNull?.innerText ?? 'NO DESC';
        print('DESC LENGTH: ${desc.length}');
        print('DESC PREVIEW: ${desc.substring(0, desc.length > 200 ? 200 : desc.length)}');
        
        final content = first.findElements('encoded').firstOrNull?.innerText ?? first.findElements('content:encoded').firstOrNull?.innerText ?? 'NO ENCODED CONTENT';
        print('ENCODED LENGTH: ${content.length}');
      }
    } catch (e) {
      print('Error: $e');
    }
    print('---');
  }
}
