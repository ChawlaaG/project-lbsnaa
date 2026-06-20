import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cadre_upsc/features/auth/services/auth_service.dart';
import 'package:cadre_upsc/features/gamification/screens/home_dashboard.dart';
import 'package:cadre_upsc/core/widgets/glass_container.dart';
import 'package:cadre_upsc/core/widgets/particle_background.dart';
import 'package:cadre_upsc/core/widgets/biometric_scanner.dart';
import 'package:cadre_upsc/core/services/sound_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    HapticFeedback.mediumImpact();
    SoundService().playButtonTap(); // Click
    setState(() => _isLoading = true);
    final userCredential = await _authService.signInWithGoogle(); // Returns UserCredential
    
    if (userCredential != null && userCredential.user != null) {
      // Check for Draft Profile Data from Onboarding
      await _syncDraftProfile(userCredential.user!.uid);

      if (mounted) {
        setState(() => _isLoading = false);
        SoundService().playLevelUp(); // Success Sound (Access Granted)
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeDashboard()),
          (route) => false,
        );
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        SoundService().playError(); // Access Denied
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Sign in failed or cancelled', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _syncDraftProfile(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('draft_name');
      final bio = prefs.getString('draft_bio');

      if (name != null || bio != null) {
        final Map<String, dynamic> updates = {};
        if (name != null && name.isNotEmpty) updates['name'] = name;
        if (bio != null && bio.isNotEmpty) updates['bio'] = bio;

        if (updates.isNotEmpty) {
           await FirebaseFirestore.instance.collection('users').doc(uid).set(
             updates, SetOptions(merge: true)
           );
           // Clear drafts
           await prefs.remove('draft_name');
           await prefs.remove('draft_bio');
        }
      }
    } catch (e) {
      debugPrint("Error syncing draft profile: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          const Positioned.fill(
            child: ParticleBackground(numberOfParticles: 20, color: Colors.blueAccent),
          ),
          Center(
            child: GlassContainer(
              padding: const EdgeInsets.all(32),
              color: Colors.black,
              opacity: 0.5,
              blur: 10,
              borderRadius: BorderRadius.circular(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Cinematic Upgrade: Biometric Scanner
                  const BiometricScanner(size: 100, color: Colors.amber), 
                  const SizedBox(height: 24),
                  const Text(
                    'CADRE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Secure Sign-In',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 48),
                  if (_isLoading)
                     const CircularProgressIndicator(color: Colors.amber)
                  else
                    ElevatedButton(
                      onPressed: _handleGoogleSignIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                )
                              ]
                            ),
                            child: const Text('G', style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF4285F4),
                            )),
                          ),
                          const SizedBox(width: 12),
                          const Text('Sign in with Google', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
