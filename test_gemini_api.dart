import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

void main() async {
  final apiKey = 'AIzaSyD_lHfd47WISN9d5R0bIx3AtziDIQHBoxY';
  
  try {
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );
    final response = await model.generateContent([Content.text('Say hello world')]);
    print('Response: ' + (response.text ?? 'null'));
  } catch(e) {
    print('Failed: ' + e.toString());
  }
}
