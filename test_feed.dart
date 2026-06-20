import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:xml/xml.dart';
import 'dart:io';

void main() async {
  const String rssUrl = 'https://www.thehindu.com/news/national/feeder/default.rss';
  final response = await http.get(Uri.parse(rssUrl));
  
  String out = 'Headers: ${response.headers['content-type']}\n';
  
  try {
    String decodedBody = utf8.decode(response.bodyBytes, allowMalformed: true);
    final document = XmlDocument.parse(decodedBody);
    final items = document.findAllElements('item');
    for (var item in items) {
      String title = item.findElements('title').first.innerText;
      if (title.contains('â') || title.contains('') || title.contains('Ã')) {
        out += 'FOUND BROKEN TITLE (utf8): $title\n';
        // Try reversing double encoding
        try {
          List<int> latin1Bytes = latin1.encode(title);
          String reversed = utf8.decode(latin1Bytes, allowMalformed: true);
          out += '  -> REVERSED: $reversed\n';
        } catch (e) {
          out += '  -> FAILED TO REVERSE: $e\n';
        }
      }
    }
  } catch (e) {
    out += 'Failed utf8 decode: $e\n';
  }

  out += '=================\n';

  try {
    final document = XmlDocument.parse(response.body);
    final items = document.findAllElements('item');
    for (var item in items) {
      String title = item.findElements('title').first.innerText;
      if (title.contains('â') || title.contains('') || title.contains('Ã')) {
        out += 'FOUND BROKEN TITLE (response.body): $title\n';
        try {
          List<int> latin1Bytes = latin1.encode(title);
          String reversed = utf8.decode(latin1Bytes, allowMalformed: true);
          out += '  -> REVERSED: $reversed\n';
        } catch (e) {
          out += '  -> FAILED TO REVERSE: $e\n';
        }
      }
    }
  } catch (e) {
    out += 'Failed response.body: $e\n';
  }
  
  File('out.txt').writeAsStringSync(out);
}
