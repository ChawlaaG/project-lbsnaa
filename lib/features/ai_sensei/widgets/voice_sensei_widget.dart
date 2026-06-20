import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:cadre_upsc/core/services/sound_service.dart';

class VoiceSenseiWidget extends StatefulWidget {
  const VoiceSenseiWidget({super.key});

  @override
  State<VoiceSenseiWidget> createState() => _VoiceSenseiWidgetState();
}

class _VoiceSenseiWidgetState extends State<VoiceSenseiWidget> with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  String _text = 'Press the mic to start';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final SoundService _soundService = SoundService();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _listen() async {
    if (!_isListening) {
      _soundService.playButtonTap();
      bool available = await _speech.initialize(
        onStatus: (val) => debugPrint('onStatus: $val'),
        onError: (val) => debugPrint('onError: $val'),
      );
      
      if (available) {
        setState(() => _isListening = true);
        _pulseController.repeat(reverse: true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _text = val.recognizedWords;
              if (val.hasConfidenceRating && val.confidence > 0) {
                 // High confidence handling or end of speech
              }
            });
            
            // Auto-respond for demo purposes if mapped
            if (!_speech.isListening) {
               _handleCommand(_text);
            }
          },
        );
      } else {
        setState(() {
          _isListening = false;
          _text = "Mic unavailable (Simulator?)";
        });
        _handleCommand("Simulation Command"); // Fallback for emulator
      }
    } else {
      setState(() => _isListening = false);
      _pulseController.stop();
      _speech.stop();
    }
  }
  
  void _handleCommand(String command) async {
    // Simple command parser
    String response = "I didn't catch that, Cadet.";
    
    if (command.toLowerCase().contains('quiz') || command.contains('Simulation')) {
      response = "Deploying Rapid Fire Quiz on Article 21. Get ready.";
    } else if (command.toLowerCase().contains('status')) {
      response = "Squad morale is high. You have 2 pending missions.";
    }

    _speak(response);
  }

  Future<void> _speak(String text) async {
    await _flutterTts.setLanguage("en-IN");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 100,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isListening || _text != 'Press the mic to start')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber),
              ),
              child: Text(
                _text,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ScaleTransition(
            scale: _pulseAnimation,
            child: FloatingActionButton(
              heroTag: 'voice_sensei',
              onPressed: _listen,
              backgroundColor: _isListening ? Colors.redAccent : Colors.teal,
              child: Icon(_isListening ? Icons.mic : Icons.mic_none),
            ),
          ),
        ],
      ),
    );
  }
}
