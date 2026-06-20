import 'dart:io';
import 'dart:convert';

void main() async {
  final apiKey = 'YOUR_GROQ_API_KEY'; // Replace with your Groq API key
  final uri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
  
  try {
    final response = await HttpClient().postUrl(uri)
      ..headers.add('Authorization', 'Bearer ' + apiKey)
      ..headers.add('Content-Type', 'application/json')
      ..write(jsonEncode({
        'model': 'llama-3.3-70b-versatile',
        'messages': [
          {'role': 'user', 'content': 'Output strictly {"test": "hello"}'}
        ]
      }));

    final httpResponse = await response.close();
    final responseBody = await httpResponse.transform(utf8.decoder).join();
    print('Groq Response: ' + responseBody);
  } catch (e) {
    print('Error: ' + e.toString());
  }
}
