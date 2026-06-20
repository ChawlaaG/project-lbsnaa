import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiEvaluationService {
  // Real app should secure this key (e.g. via --dart-define or backend)
  // Placeholder for prototype
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? 'YOUR_API_KEY_HERE'; 
  late final GenerativeModel _model;

  GeminiEvaluationService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
  }

  Future<Map<String, dynamic>> evaluateAnswer(File imageFile, String question) async {
    try {
      await _checkRateLimit(); // Check rate limit before processing
      final imageBytes = await imageFile.readAsBytes();
      final content = [
        Content.multi([
          TextPart('''
You are a strict UPSC Mains Examiner. You value structure (Intro-Body-Conclusion), facts, and keywords.
Question: $question
Look at the attached handwritten image. Evaluate the answer. 
Return the response in this strictly valid JSON format: 
{ 
  "score": "X/10", 
  "strengths": ["point 1", "point 2"], 
  "weaknesses": ["point 1", "point 2"], 
  "missing_keywords": ["keyword 1", "keyword 2"],
  "overall_comment": "Brief summary" 
}
Do not add any markdown formatting (like ```json) outside the JSON.
'''),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _model.generateContent(content);
      
      final responseText = response.text;
      if (responseText == null) {
        throw Exception('No response from AI');
      }

      // Cleanup potential markdown if strict instructions failed
      final cleanJson = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      
      return jsonDecode(cleanJson);
    } catch (e) {
      if (e.toString().contains('Rate limit exceeded')) {
         return {
          "score": "0/10",
          "strengths": ["Rate Limit Hit"],
          "weaknesses": ["Please wait 5 seconds before next request."],
          "missing_keywords": [],
          "overall_comment": "Cooldown active."
        };
      }
      // Fallback/Error state for prototype
      return {
        "score": "0/10",
        "strengths": ["Error analyzing image"],
        "weaknesses": [e.toString()],
        "missing_keywords": [],
        "overall_comment": "Please try again."
      };
    }
  }

  // Zero-Budget Constraint: Rate Limiter (1 req / 5s)
  DateTime? _lastRequestTime;
  
  Future<void> _checkRateLimit() async {
    if (_lastRequestTime != null) {
      final difference = DateTime.now().difference(_lastRequestTime!);
      if (difference.inSeconds < 5) {
        throw Exception('Rate limit exceeded. Zero-Budget Protocol active.');
      }
    }
    _lastRequestTime = DateTime.now();
  }
}
