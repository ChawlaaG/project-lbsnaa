import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/gemini_evaluation_service.dart';
import 'package:cadre_upsc/features/ai_sensei/widgets/evaluation_result_widget.dart';

class AnswerSubmissionScreen extends StatefulWidget {
  const AnswerSubmissionScreen({super.key});

  @override
  State<AnswerSubmissionScreen> createState() => _AnswerSubmissionScreenState();
}

class _AnswerSubmissionScreenState extends State<AnswerSubmissionScreen> {
  final TextEditingController _questionController = TextEditingController();
  final GeminiEvaluationService _aiService = GeminiEvaluationService();
  File? _selectedImage;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _analysisResult = null; // Reset result on new image
      });
    }
  }

  Future<void> _evaluateAnswer() async {
    if (_selectedImage == null || _questionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a question and an image')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final result = await _aiService.evaluateAnswer(_selectedImage!, _questionController.text);
      if (mounted) {
        setState(() {
          _analysisResult = result;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('AI SENSEI'),
        backgroundColor: const Color(0xFF16213E),
        elevation: 0,
      ),
      body: _analysisResult != null 
          ? EvaluationResultWidget(evaluation: _analysisResult!)
          : _buildSubmissionForm(),
    );
  }

  Widget _buildSubmissionForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'EXAM HALL',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          // Question Input
          TextField(
            controller: _questionController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter the Question here...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              filled: true,
              fillColor: const Color(0xFF0F3460),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),

          // Image Picker Area
          GestureDetector(
            onTap: () => _pickImage(ImageSource.camera),
            child: Container(
              height: 250,
              decoration: BoxDecoration(
                color: const Color(0xFF0F3460),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(_selectedImage!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.camera_alt_rounded, size: 64, color: Colors.white24),
                        const SizedBox(height: 16),
                        const Text(
                          'Tap to Upload Answer',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 32),

          // Evaluate Button
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isAnalyzing ? null : _evaluateAnswer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isAnalyzing 
                ? const CircularProgressIndicator()
                : const Text('EVALUATE NOW', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
