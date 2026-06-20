import 'package:vibration/vibration.dart';
import 'package:flutter/foundation.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  bool _enabled = true;
  void setEnabled(bool value) => _enabled = value;

  Future<void> playLevelUp() async {
    if (!_enabled) return;
    try {
      debugPrint('Playing Level Up Sound');
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(pattern: [0, 500, 100, 500]);
      }
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  Future<void> playButtonTap() async {
    if (!_enabled) return;
    try {
       if (await Vibration.hasVibrator()) {
         Vibration.vibrate(duration: 15);
       }
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  Future<void> playError() async {
    if (!_enabled) return;
    try {
      debugPrint('Buzz');
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 100);
      }
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }
}
