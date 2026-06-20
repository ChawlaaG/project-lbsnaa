import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'dart:convert';
import 'dart:io';

void main() async {
  final url = 'https://www.thehindu.com/news/national/feeder/default.rss';
  final response = await http.get(Uri.parse(url));
  
  String out = "";

  try {
    final doc1 = XmlDocument.parse(response.body);
    final items1 = doc1.findAllElements('title').skip(1);
    final str1 = items1.firstWhere((e) => e.innerText.contains('â') || e.innerText.contains('') || e.innerText.contains('Modi'), orElse: () => items1.first).innerText;
    out += "BODY: $str1\n";
  } catch (e) { out += "BODY ERROR: $e\n"; }

  try {
    final doc2 = XmlDocument.parse(utf8.decode(response.bodyBytes, allowMalformed: true));
    final items2 = doc2.findAllElements('title').skip(1);
    final str2 = items2.firstWhere((e) => e.innerText.contains('â') || e.innerText.contains('') || e.innerText.contains('Modi'), orElse: () => items2.first).innerText;
    out += "UTF8: $str2\n";
  } catch (e) { out += "UTF8 ERROR: $e\n"; }
  
  try {
    final doc3 = XmlDocument.parse(latin1.decode(response.bodyBytes, allowInvalid: true));
    final items3 = doc3.findAllElements('title').skip(1);
    final str3 = items3.firstWhere((e) => e.innerText.contains('â') || e.innerText.contains('') || e.innerText.contains('Modi'), orElse: () => items3.first).innerText;
    out += "LATIN1: $str3\n";
  } catch (e) { out += "LATIN1 ERROR: $e\n"; }

  File('c:/Users/manis/.gemini/antigravity/scratch/project_lbsnaa/lib/out_encoding.txt').writeAsStringSync(out);
}
