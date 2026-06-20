import 'dart:io';
import 'dart:convert';

void main() async {
  // Load API key from environment variable (set in .env file — never hardcode!)
  final apiKey = Platform.environment['GROQ_API_KEY'] ?? '';
  if (apiKey.isEmpty) {
    print('ERROR: GROQ_API_KEY not set. Add it to your .env file.');
    return;
  }

  final uri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

  try {
    final request = await HttpClient().postUrl(uri);
    request.headers.add('Authorization', 'Bearer $apiKey');
    request.headers.add('Content-Type', 'application/json');
    request.write(jsonEncode({
      'model': 'llama-3.3-70b-versatile',
      'messages': [
        {'role': 'user', 'content': 'Output strictly {"test": "hello"}'}
      ]
    }));

    final httpResponse = await request.close();
    final responseBody = await httpResponse.transform(utf8.decoder).join();
    print('Groq Response: $responseBody');
  } catch (e) {
    print('Error: $e');
  }
}
