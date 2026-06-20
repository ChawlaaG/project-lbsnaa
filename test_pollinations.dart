import 'dart:io';
import 'dart:convert';

void main() async {
  final url = Uri.parse('https://text.pollinations.ai/');
  final request = await HttpClient().postUrl(url);
  request.headers.contentType = ContentType.json;
  
  final body = jsonEncode({
    "messages": [
      {"role": "system", "content": "You are a helpful assistant."},
      {"role": "user", "content": "Say hello world"}
    ],
    "model": "qwen-coder" // or "openai" or "mistral"
  });
  
  request.write(body);
  final response = await request.close();
  final responseBody = await response.transform(utf8.decoder).join();
  print('Response: ' + responseBody);
}
